package engine

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"simulator/military/publisher"
	bfpb "simulator/proto"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"
)

const (
	missileTickInterval = 10 * time.Millisecond
	missileCount        = 4

	missileAltMin   = 3000.0
	missileAltMax   = 10000.0
	missileSpeedMin = 500.0
	missileSpeedMax = 900.0
)

// MissileEngine quản lý tất cả missile objects
type MissileEngine struct {
	pub      *publisher.NatsPublisher
	missiles []*uavState
}

func NewMissileEngine(pub *publisher.NatsPublisher) *MissileEngine {
	e := &MissileEngine{pub: pub}
	for i := 0; i < missileCount; i++ {
		e.missiles = append(e.missiles, &uavState{
			id:      fmt.Sprintf("MSL-%03d", i+1),
			lat:     latMin + rand.Float64()*(latMax-latMin),
			lon:     lonMin + rand.Float64()*(lonMax-lonMin),
			alt:     missileAltMin + rand.Float64()*(missileAltMax-missileAltMin),
			heading: rand.Float64() * 360,
			speed:   missileSpeedMin + rand.Float64()*(missileSpeedMax-missileSpeedMin),
		})
	}
	log.Printf("[missile-engine] Spawned %d missiles", missileCount)
	return e
}

func (e *MissileEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(missileTickInterval)
	defer ticker.Stop()
	log.Println("[missile-engine] Started – tick every", missileTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[missile-engine] Shutdown")
			return
		case <-ticker.C:
			for _, m := range e.missiles {
				move(m, missileTickInterval)
				e.pub.Publish(&bfpb.MilitaryEvent{
					Id:          m.id,
					Type:        bfpb.ObjectType_MISSILE,
					Lat:         m.lat,
					Lon:         m.lon,
					Alt:         m.alt,
					Heading:     m.heading,
					Speed:       m.speed,
					ThreatLevel: bfpb.ThreatLevel_CRITICAL,
					Status:      "ACTIVE",
					Ts:          timestamppb.Now(),
				})
			}
		}
	}
}
