package service

import (
	"context"
	"database/sql"
	"log"
	"math"
	"sync"
	"time"

	_ "github.com/lib/pq"
	"github.com/nats-io/nats.go"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
	bfpb "simulator/proto"
)

const earthRadiusM = 6371000.0

type activeFlight struct {
	icao24      string
	callsign    string
	lat         float64
	lon         float64
	alt         float64
	heading     float64
	speed       float64
	lastUpdated time.Time
}

type HistoricalPoller struct {
	db             *sql.DB
	nc             *nats.Conn
	currentSimTime time.Time

	activeFlights map[string]*activeFlight
	mu            sync.RWMutex
}

func NewHistoricalPoller(db *sql.DB, nc *nats.Conn) *HistoricalPoller {
	return &HistoricalPoller{
		db:            db,
		nc:            nc,
		activeFlights: make(map[string]*activeFlight),
	}
}

func (p *HistoricalPoller) Run(ctx context.Context) {
	// Find the earliest time in history to start the simulation
	var startTime time.Time
	err := p.db.QueryRowContext(ctx, "SELECT MIN(snapshot_at) FROM track_history").Scan(&startTime)
	if err != nil || startTime.IsZero() {
		log.Printf("[historical-poller] Failed to find start time, checking if table is empty: %v", err)
		return
	}

	log.Printf("[historical-poller] Starting replay from %v", startTime)
	p.currentSimTime = startTime

	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("[historical-poller] Shutting down")
			return
		case <-ticker.C:
			// 1. Fetch any new snapshots in the current 1-sec window
			endTime := p.currentSimTime.Add(1 * time.Second)
			p.fetchSnapshots(ctx, p.currentSimTime, endTime)
			p.currentSimTime = endTime

			// 2. Tick and publish all active flights
			p.tickAndPublish()
		}
	}
}

func (p *HistoricalPoller) fetchSnapshots(ctx context.Context, start, end time.Time) {
	rows, err := p.db.QueryContext(ctx, `
		SELECT h.icao24, a.callsign, h.latitude, h.longitude, h.altitude, h.heading, h.speed
		FROM track_history h
		JOIN aircraft a ON h.icao24 = a.icao24
		WHERE h.snapshot_at >= $1 AND h.snapshot_at < $2
	`, start, end)

	if err != nil {
		log.Printf("[historical-poller] Query error: %v", err)
		return
	}
	defer rows.Close()

	p.mu.Lock()
	defer p.mu.Unlock()

	count := 0
	for rows.Next() {
		var icao24, callsign string
		var lat, lon, alt, heading, speed float64

		if err := rows.Scan(&icao24, &callsign, &lat, &lon, &alt, &heading, &speed); err != nil {
			log.Printf("[historical-poller] Row scan error: %v", err)
			continue
		}

		p.activeFlights[icao24] = &activeFlight{
			icao24:      icao24,
			callsign:    callsign,
			lat:         lat,
			lon:         lon,
			alt:         alt,
			heading:     heading,
			speed:       speed,
			lastUpdated: p.currentSimTime,
		}
		count++
	}

	// Clean up stale flights (no update from DB for > 30s)
	for id, f := range p.activeFlights {
		if p.currentSimTime.Sub(f.lastUpdated) > 30*time.Second {
			delete(p.activeFlights, id)
		}
	}

	if count > 0 {
		log.Printf("[historical-poller] Synced %d flights from DB snapshot", count)
	}
}

func (p *HistoricalPoller) tickAndPublish() {
	p.mu.Lock()
	flights := make([]*activeFlight, 0, len(p.activeFlights))
	for _, f := range p.activeFlights {
		// Move flight forward by 1 second based on its speed and heading
		distM := f.speed * 1.0
		if distM > 0 {
			f.lat, f.lon = movePosition(f.lat, f.lon, f.heading, distM)
		}

		// Create a copy for publishing
		flights = append(flights, &activeFlight{
			icao24:   f.icao24,
			callsign: f.callsign,
			lat:      f.lat,
			lon:      f.lon,
			alt:      f.alt,
			heading:  f.heading,
			speed:    f.speed,
		})
	}
	p.mu.Unlock()

	if len(flights) == 0 {
		return
	}

	// Spread publishing over 800ms to avoid overwhelming NATS/Postgres
	sleepDur := 800 * time.Millisecond / time.Duration(len(flights))

	go func(flist []*activeFlight) {
		for _, f := range flist {
			event := &bfpb.FlightEvent{
				Icao24:   f.icao24,
				Callsign: f.callsign,
				Lat:      f.lat,
				Lon:      f.lon,
				Alt:      f.alt,
				Speed:    f.speed,
				Heading:  f.heading,
				Ts:       timestamppb.New(time.Now()),
			}
			data, err := proto.Marshal(event)
			if err == nil {
				// subjectFlightPosition is defined in opensky_client.go
				p.nc.Publish(subjectFlightPosition, data)
			}
			time.Sleep(sleepDur)
		}
	}(flights)
}

// movePosition calculates new coordinates using Haversine approximation
func movePosition(lat, lon, headingDeg, distM float64) (float64, float64) {
	ang := distM / earthRadiusM
	hr := headingDeg * math.Pi / 180.0
	la := lat * math.Pi / 180.0
	lo := lon * math.Pi / 180.0

	lat2 := math.Asin(math.Sin(la)*math.Cos(ang) + math.Cos(la)*math.Sin(ang)*math.Cos(hr))
	lon2 := lo + math.Atan2(
		math.Sin(hr)*math.Sin(ang)*math.Cos(la),
		math.Cos(ang)-math.Sin(la)*math.Sin(lat2),
	)
	return lat2 * 180.0 / math.Pi, lon2 * 180.0 / math.Pi
}
