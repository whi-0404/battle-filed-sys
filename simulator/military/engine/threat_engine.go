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
	threatTickInterval = 50 * time.Millisecond
	threatCount        = 6

	threatAltMin   = 100.0
	threatAltMax   = 8000.0
	threatSpeedMin = 50.0
	threatSpeedMax = 300.0
)

type ThreatEngine struct {
	pub     *publisher.NatsPublisher
	threats []*uavState
	levels  []bfpb.ThreatLevel
}

func NewThreatEngine(pub *publisher.NatsPublisher) *ThreatEngine {
	levels := []bfpb.ThreatLevel{
		bfpb.ThreatLevel_LOW,
		bfpb.ThreatLevel_MEDIUM,
		bfpb.ThreatLevel_HIGH,
		bfpb.ThreatLevel_CRITICAL,
	}

	e := &ThreatEngine{pub: pub, levels: levels}
	for i := 0; i < threatCount; i++ {
		e.threats = append(e.threats, &uavState{
			id:      fmt.Sprintf("THR-%03d", i+1),
			lat:     latMin + rand.Float64()*(latMax-latMin),
			lon:     lonMin + rand.Float64()*(lonMax-lonMin),
			alt:     threatAltMin + rand.Float64()*(threatAltMax-threatAltMin),
			heading: rand.Float64() * 360,
			speed:   threatSpeedMin + rand.Float64()*(threatSpeedMax-threatSpeedMin),
		})
	}
	log.Printf("[threat-engine] Spawned %d threats", threatCount)
	return e
}

func (e *ThreatEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(threatTickInterval)
	defer ticker.Stop()
	log.Println("[threat-engine] Started – tick every", threatTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[threat-engine] Shutdown")
			return
		case <-ticker.C:
			for i, t := range e.threats {
				move(t, threatTickInterval)
				e.pub.Publish(&bfpb.MilitaryEvent{
					Id:          t.id,
					Type:        bfpb.ObjectType_THREAT,
					Lat:         t.lat,
					Lon:         t.lon,
					Alt:         t.alt,
					Heading:     t.heading,
					Speed:       t.speed,
					ThreatLevel: e.levels[i%len(e.levels)],
					Status:      "ACTIVE",
					Ts:          timestamppb.Now(),
				})
			}
		}
	}
}
