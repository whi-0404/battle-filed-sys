package engine

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/rand"
	"simulator/military/model"
	"simulator/military/publisher"
	"sync"
	"time"
)

const (
	threatTickInterval = 50 * time.Millisecond
	threatMaxCount     = 8

	threatSpeedMin  = 50.0
	threatSpeedMax  = 300.0
	threatAltMin    = 100.0
	threatAltMax    = 10000.0
	threatLifeMin   = 30
	threatLifeMax   = 120
	threatSpawnRate = 8
)

type ThreatEngine struct {
	pub      *publisher.NatsPublisher
	threats  map[string]*model.MilitaryObject
	mu       sync.RWMutex
	idxCount int
}

func NewThreatEngine(pub *publisher.NatsPublisher) *ThreatEngine {
	e := &ThreatEngine{
		pub:     pub,
		threats: make(map[string]*model.MilitaryObject),
	}
	for i := 0; i < 3; i++ {
		t := e.newThreat()
		e.threats[t.ID] = t
	}
	log.Printf("[threat-engine] Initialized with %d threats", len(e.threats))
	return e
}

func (e *ThreatEngine) newThreat() *model.MilitaryObject {
	e.idxCount++

	var lvl model.ThreatLevel
	r := rand.Float64()
	switch {
	case r < 0.40:
		lvl = model.ThreatLow
	case r < 0.70:
		lvl = model.ThreatMedium
	case r < 0.90:
		lvl = model.ThreatHigh
	default:
		lvl = model.ThreatCritical
	}

	lifeSeconds := threatLifeMin + rand.Intn(threatLifeMax-threatLifeMin)

	return &model.MilitaryObject{
		ID:          fmt.Sprintf("THR-%04d", e.idxCount),
		Type:        model.ObjThreat,
		Status:      model.StatusActive,
		Lat:         uavLatMin + rand.Float64()*(uavLatMax-uavLatMin),
		Lon:         uavLonMin + rand.Float64()*(uavLonMax-uavLonMin),
		Alt:         threatAltMin + rand.Float64()*(threatAltMax-threatAltMin),
		Heading:     rand.Float64() * 360,
		Speed:       threatSpeedMin + rand.Float64()*(threatSpeedMax-threatSpeedMin),
		ThreatLevel: lvl,
		ThreatExpiry: time.Now().Add(
			time.Duration(lifeSeconds) * time.Second,
		).Unix(),
	}
}

func (e *ThreatEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(threatTickInterval)
	spawnTicker := time.NewTicker(threatSpawnRate * time.Second)
	defer ticker.Stop()
	defer spawnTicker.Stop()

	log.Println("[threat-engine] Started – tick every", threatTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[threat-engine] Shutting down")
			return

		case <-spawnTicker.C:
			e.mu.Lock()
			if len(e.threats) < threatMaxCount {
				t := e.newThreat()
				e.threats[t.ID] = t
				log.Printf("[threat-engine] New threat spawned: %s (level=%s)", t.ID, t.ThreatLevel)
			}
			e.mu.Unlock()

		case <-ticker.C:
			now := time.Now().Unix()
			e.mu.Lock()
			for id, t := range e.threats {
				if now > t.ThreatExpiry {
					delete(e.threats, id)
					log.Printf("[threat-engine] Threat %s expired", id)
					continue
				}

				e.updateThreat(t)
				e.pub.Publish(toEvent(t))
			}
			e.mu.Unlock()
		}
	}
}

// updateThreat cập nhật vị trí threat – chuyển động không dự đoán được
func (e *ThreatEngine) updateThreat(t *model.MilitaryObject) {
	dtHours := threatTickInterval.Hours()

	// Erratic heading change – thay đổi heading ngẫu nhiên mạnh hơn UAV
	wobble := (rand.Float64()*20 - 10) // ±10° mỗi tick
	t.Heading = normalizeDeg(t.Heading + wobble)

	// Boundary check
	distKm := knotsToKmh(t.Speed) * dtHours
	newLat, newLon := movePosition(t.Lat, t.Lon, t.Heading, distKm)
	if newLat < uavLatMin || newLat > uavLatMax || newLon < uavLonMin || newLon > uavLonMax {
		t.Heading = normalizeDeg(t.Heading + 180)
		newLat, newLon = movePosition(t.Lat, t.Lon, t.Heading, distKm)
	}
	t.Lat = newLat
	t.Lon = newLon

	// Altitude jitter
	altJitter := rand.Float64()*100 - 50
	t.Alt = clamp(t.Alt+altJitter, threatAltMin, threatAltMax)
}

func normalizeDeg(d float64) float64 {
	for d < 0 {
		d += 360
	}
	return math.Mod(d, 360)
}

func clamp(v, min, max float64) float64 {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}
