package engine

import (
	"simulator/military/publisher"
	bfpb "simulator/proto"
	"time"
)

// NewThreatEngine creates a new Threat engine instance
func NewThreatEngine(pub *publisher.NatsPublisher) Engine {
	levels := []bfpb.ThreatLevel{
		bfpb.ThreatLevel_LOW,
		bfpb.ThreatLevel_MEDIUM,
		bfpb.ThreatLevel_HIGH,
		bfpb.ThreatLevel_CRITICAL,
	}

	cfg := Config{
		Name:         "threat-engine",
		Prefix:       "THR",
		Count:        200,
		TickInterval: 50 * time.Millisecond,
		AltMin:       100.0,
		AltMax:       8000.0,
		SpeedMin:     50.0,
		SpeedMax:     300.0,
		ObjectType:   bfpb.ObjectType_THREAT,
		ThreatFunc: func(index int) bfpb.ThreatLevel {
			return levels[index%len(levels)]
		},
	}
	return NewBaseEngine(pub, cfg)
}
