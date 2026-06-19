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
	missileTickInterval = 10 * time.Millisecond
	missileCount        = 4

	missileAltCruise   = 8000.0
	missileAltTerminal = 200.0
	missileSpeedCruise = 700.0
	missileSpeedMax    = 900.0

	missileRespawnDelaySec = 20
)

type MissileEngine struct {
	pub      *publisher.NatsPublisher
	missiles []*model.MilitaryObject
	mu       sync.RWMutex
	idxCount int
}

func NewMissileEngine(pub *publisher.NatsPublisher) *MissileEngine {
	e := &MissileEngine{pub: pub}
	e.spawnMissiles()
	return e
}

func (e *MissileEngine) spawnMissiles() {
	e.missiles = make([]*model.MilitaryObject, missileCount)
	for i := 0; i < missileCount; i++ {
		e.missiles[i] = e.newMissile(i)
	}
	log.Printf("[missile-engine] Spawned %d missiles", missileCount)
}

func (e *MissileEngine) newMissile(idx int) *model.MilitaryObject {
	e.idxCount++
	launchLat := uavLatMin + rand.Float64()*(uavLatMax-uavLatMin)
	launchLon := uavLonMin + rand.Float64()*(uavLonMax-uavLonMin)

	targetLat := uavLatMin + rand.Float64()*(uavLatMax-uavLatMin)
	targetLon := uavLonMin + rand.Float64()*(uavLonMax-uavLonMin)

	distKm := haversine(launchLat, launchLon, targetLat, targetLon)

	return &model.MilitaryObject{
		ID:               fmt.Sprintf("MSL-%03d", e.idxCount),
		Type:             model.ObjMissile,
		Status:           model.StatusActive,
		Lat:              launchLat,
		Lon:              launchLon,
		Alt:              missileAltCruise,
		Heading:          bearingTo(launchLat, launchLon, targetLat, targetLon),
		Speed:            missileSpeedCruise,
		TargetLat:        targetLat,
		TargetLon:        targetLon,
		RemainingRangeKm: distKm,
		ThreatLevel:      model.ThreatCritical,
	}
}

func (e *MissileEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(missileTickInterval)
	defer ticker.Stop()

	log.Println("[missile-engine] Started – tick every", missileTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[missile-engine] Shutting down")
			return
		case <-ticker.C:
			e.mu.Lock()
			for i, m := range e.missiles {
				e.updateMissile(m)

				if m.Status == model.StatusDestroyed {
					log.Printf("[missile-engine] %s hit target, scheduling respawn", m.ID)
					go func(idx int) {
						time.Sleep(time.Duration(missileRespawnDelaySec) * time.Second)
						e.mu.Lock()
						e.missiles[idx] = e.newMissile(idx)
						log.Printf("[missile-engine] Respawned new missile at slot %d", idx)
						e.mu.Unlock()
					}(i)
					continue
				}

				e.pub.Publish(toEvent(m))
			}
			e.mu.Unlock()
		}
	}
}

func (e *MissileEngine) updateMissile(m *model.MilitaryObject) {
	dtHours := missileTickInterval.Hours()

	distToTarget := haversine(m.Lat, m.Lon, m.TargetLat, m.TargetLon)
	m.RemainingRangeKm = distToTarget

	if distToTarget < 20.0 {
		m.Status = model.StatusTerminal
		altDrop := (m.Alt - missileAltTerminal) * 0.05
		m.Alt = math.Max(missileAltTerminal, m.Alt-altDrop)
		m.Speed = math.Min(missileSpeedMax, m.Speed*1.001)
	}

	if distToTarget < 0.3 {
		m.Status = model.StatusDestroyed
		log.Printf("[missile-engine] %s IMPACT at (%.4f, %.4f)", m.ID, m.TargetLat, m.TargetLon)
		return
	}

	m.Heading = bearingTo(m.Lat, m.Lon, m.TargetLat, m.TargetLon)

	distKm := knotsToKmh(m.Speed) * dtHours
	m.Lat, m.Lon = movePosition(m.Lat, m.Lon, m.Heading, distKm)
}
