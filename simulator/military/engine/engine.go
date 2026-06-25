package engine

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/rand"
	"simulator/military/publisher"
	bfpb "simulator/proto"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"
)

// Engine defines the interface for all simulation engines
type Engine interface {
	Run(ctx context.Context)
}

// bbox earth
const (
	latMin = -90.0
	latMax = 90.0
	lonMin = -180.0
	lonMax = 180.0
)

// ObjectState lưu trạng thái nội bộ của một object (không serialize)
type ObjectState struct {
	id      string
	lat     float64
	lon     float64
	alt     float64
	heading float64
	speed   float64
}

// Config holds parameters for an engine
type Config struct {
	Name         string
	Prefix       string
	Count        int
	TickInterval time.Duration
	AltMin       float64
	AltMax       float64
	SpeedMin     float64
	SpeedMax     float64
	ObjectType   bfpb.ObjectType
	ThreatFunc   func(index int) bfpb.ThreatLevel
}

// BaseEngine implements the Engine interface
type BaseEngine struct {
	cfg     Config
	pub     *publisher.NatsPublisher
	objects []*ObjectState
}

// NewBaseEngine creates a new BaseEngine instance
func NewBaseEngine(pub *publisher.NatsPublisher, cfg Config) *BaseEngine {
	e := &BaseEngine{
		cfg: cfg,
		pub: pub,
	}
	for i := 0; i < cfg.Count; i++ {
		e.objects = append(e.objects, &ObjectState{
			id:      fmt.Sprintf("%s-%03d", cfg.Prefix, i+1),
			lat:     latMin + rand.Float64()*(latMax-latMin),
			lon:     lonMin + rand.Float64()*(lonMax-lonMin),
			alt:     cfg.AltMin + rand.Float64()*(cfg.AltMax-cfg.AltMin),
			heading: rand.Float64() * 360,
			speed:   cfg.SpeedMin + rand.Float64()*(cfg.SpeedMax-cfg.SpeedMin),
		})
	}
	log.Printf("[%s] Spawned %d objects", cfg.Name, cfg.Count)
	return e
}

// Run starts the engine simulation loop
func (e *BaseEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(e.cfg.TickInterval)
	defer ticker.Stop()
	log.Printf("[%s] Started – tick every %v", e.cfg.Name, e.cfg.TickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Printf("[%s] Shutdown", e.cfg.Name)
			return
		case <-ticker.C:
			for i, obj := range e.objects {
				move(obj, e.cfg.TickInterval)
				e.pub.Publish(&bfpb.MilitaryEvent{
					Id:          obj.id,
					Type:        e.cfg.ObjectType,
					Lat:         obj.lat,
					Lon:         obj.lon,
					Alt:         obj.alt,
					Heading:     obj.heading,
					Speed:       obj.speed,
					ThreatLevel: e.cfg.ThreatFunc(i),
					Status:      "ACTIVE",
					Ts:          timestamppb.Now(),
				})
			}
		}
	}
}

// ─── Geo math & movement ──────────────────────────────────────────────────

// move di chuyển ObjectState theo heading + bounce khi ra biên
func move(s *ObjectState, dt time.Duration) {
	distKm := knotsToKmh(s.speed) * dt.Hours()

	newLat, newLon := movePosition(s.lat, s.lon, s.heading, distKm)

	if newLat < latMin || newLat > latMax || newLon < lonMin || newLon > lonMax {
		s.heading = math.Mod(s.heading+180, 360)
		newLat, newLon = movePosition(s.lat, s.lon, s.heading, distKm)
	}

	s.lat = newLat
	s.lon = newLon
	s.heading = math.Mod(s.heading+(rand.Float64()*4-2)+360, 360)
}

const earthRadiusKm = 6371.0

func deg2rad(d float64) float64 { return d * math.Pi / 180 }
func rad2deg(r float64) float64 { return r * 180 / math.Pi }

func movePosition(lat, lon, headingDeg, distKm float64) (float64, float64) {
	ang := distKm / earthRadiusKm
	hr := deg2rad(headingDeg)
	la := deg2rad(lat)
	lo := deg2rad(lon)

	lat2 := math.Asin(math.Sin(la)*math.Cos(ang) +
		math.Cos(la)*math.Sin(ang)*math.Cos(hr))
	lon2 := lo + math.Atan2(
		math.Sin(hr)*math.Sin(ang)*math.Cos(la),
		math.Cos(ang)-math.Sin(la)*math.Sin(lat2),
	)
	return rad2deg(lat2), rad2deg(lon2)
}

func knotsToKmh(k float64) float64 { return k * 1.852 }
