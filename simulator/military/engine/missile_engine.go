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

	missileAltCruise  = 8000.0  // mét hành trình
	missileAltTerminal = 200.0  // mét cuối hành trình
	missileSpeedCruise = 700.0  // knots
	missileSpeedMax    = 900.0  // knots

	missileRespawnDelaySec = 20 // giây sau khi hit target thì respawn
)

// MissileEngine quản lý toàn bộ missile objects
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

// newMissile tạo missile mới với launch point và target ngẫu nhiên trong bbox VN
func (e *MissileEngine) newMissile(idx int) *model.MilitaryObject {
	e.idxCount++
	// Launch từ biển Đông hoặc biên giới
	launchLat := uavLatMin + rand.Float64()*(uavLatMax-uavLatMin)
	launchLon := uavLonMin + rand.Float64()*(uavLonMax-uavLonMin)

	// Target là điểm khác trong bbox
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

// Run bắt đầu missile engine loop
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
					// Respawn missile sau một khoảng thời gian
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

// updateMissile cập nhật vị trí và trạng thái của một missile
func (e *MissileEngine) updateMissile(m *model.MilitaryObject) {
	dtHours := missileTickInterval.Hours()

	distToTarget := haversine(m.Lat, m.Lon, m.TargetLat, m.TargetLon)
	m.RemainingRangeKm = distToTarget

	// Terminal phase: khi còn < 20km thì bổ nhào xuống
	if distToTarget < 20.0 {
		m.Status = model.StatusTerminal
		// Giảm altitude xuống terminal altitude
		altDrop := (m.Alt - missileAltTerminal) * 0.05
		m.Alt = math.Max(missileAltTerminal, m.Alt-altDrop)
		// Tăng tốc trong giai đoạn terminal
		m.Speed = math.Min(missileSpeedMax, m.Speed*1.001)
	}

	// Đã đến target → destroy
	if distToTarget < 0.3 {
		m.Status = model.StatusDestroyed
		log.Printf("[missile-engine] %s IMPACT at (%.4f, %.4f)", m.ID, m.TargetLat, m.TargetLon)
		return
	}

	// Luôn hướng về target
	m.Heading = bearingTo(m.Lat, m.Lon, m.TargetLat, m.TargetLon)

	// Di chuyển
	distKm := knotsToKmh(m.Speed) * dtHours
	m.Lat, m.Lon = movePosition(m.Lat, m.Lon, m.Heading, distKm)
}
