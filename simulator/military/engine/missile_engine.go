package engine

import (
	"simulator/military/publisher"
	bfpb "simulator/proto"
	"time"
)

// NewMissileEngine creates a new Missile engine instance
func NewMissileEngine(pub *publisher.NatsPublisher) Engine {
	cfg := Config{
		Name:         "missile-engine",
		Prefix:       "MSL",
		Count:        100,
		TickInterval: 10 * time.Millisecond,
		AltMin:       3000.0,
		AltMax:       10000.0,
		SpeedMin:     500.0,
		SpeedMax:     900.0,
		ObjectType:   bfpb.ObjectType_MISSILE,
		ThreatFunc: func(index int) bfpb.ThreatLevel {
			return bfpb.ThreatLevel_CRITICAL
		},
	}
	return NewBaseEngine(pub, cfg)
}
