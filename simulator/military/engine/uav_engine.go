package engine

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/rand"
	bfpb "simulator/proto"
	"simulator/military/publisher"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"
)

const (
	uavTickInterval = 20 * time.Millisecond
	uavCount        = 15

	// Bounding box Việt Nam
	latMin = 9.0
	latMax = 23.0
	lonMin = 102.5
	lonMax = 109.5

	uavAltMin   = 500.0
	uavAltMax   = 5000.0
	uavSpeedMin = 80.0
	uavSpeedMax = 180.0
)

// uavState lưu trạng thái nội bộ của một UAV (không serialize)
type uavState struct {
	id      string
	lat     float64
	lon     float64
	alt     float64
	heading float64
	speed   float64
}

// UAVEngine quản lý tất cả UAV objects
type UAVEngine struct {
	pub  *publisher.NatsPublisher
	uavs []*uavState
}

func NewUAVEngine(pub *publisher.NatsPublisher) *UAVEngine {
	e := &UAVEngine{pub: pub}
	for i := 0; i < uavCount; i++ {
		e.uavs = append(e.uavs, &uavState{
			id:      fmt.Sprintf("UAV-%03d", i+1),
			lat:     latMin + rand.Float64()*(latMax-latMin),
			lon:     lonMin + rand.Float64()*(lonMax-lonMin),
			alt:     uavAltMin + rand.Float64()*(uavAltMax-uavAltMin),
			heading: rand.Float64() * 360,
			speed:   uavSpeedMin + rand.Float64()*(uavSpeedMax-uavSpeedMin),
		})
	}
	log.Printf("[uav-engine] Spawned %d UAVs", uavCount)
	return e
}

func (e *UAVEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(uavTickInterval)
	defer ticker.Stop()
	log.Println("[uav-engine] Started – tick every", uavTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[uav-engine] Shutdown")
			return
		case <-ticker.C:
			for _, uav := range e.uavs {
				move(uav, uavTickInterval)
				e.pub.Publish(&bfpb.MilitaryEvent{
					Id:          uav.id,
					Type:        bfpb.ObjectType_UAV,
					Lat:         uav.lat,
					Lon:         uav.lon,
					Alt:         uav.alt,
					Heading:     uav.heading,
					Speed:       uav.speed,
					ThreatLevel: bfpb.ThreatLevel_LOW,
					Status:      "ACTIVE",
					Ts:          timestamppb.Now(),
				})
			}
		}
	}
}

// ─── Internal state & shared movement helpers ─────────────────────

// move di chuyển uavState theo heading + bounce khi ra biên
func move(s *uavState, dt time.Duration) {
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

// ─── Geo math ─────────────────────────────────────────────────────

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
