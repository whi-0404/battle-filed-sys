package engine

import (
	"simulator/military/publisher"
	bfpb "simulator/proto"
	"time"
)

// NewUAVEngine creates a new UAV engine instance
func NewUAVEngine(pub *publisher.NatsPublisher) Engine {
	cfg := Config{
		Name:         "uav-engine",
		Prefix:       "UAV",
		Count:        500,
		TickInterval: 20 * time.Millisecond,
		AltMin:       500.0,
		AltMax:       5000.0,
		SpeedMin:     80.0,
		SpeedMax:     180.0,
		ObjectType:   bfpb.ObjectType_UAV,
		ThreatFunc: func(index int) bfpb.ThreatLevel {
			return bfpb.ThreatLevel_LOW
		},
	}
	return NewBaseEngine(pub, cfg)
}
