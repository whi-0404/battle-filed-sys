package model

import "time"

// MilitaryEvent là payload nhận từ NATS subject "military.position.updated"
type MilitaryEvent struct {
	// Identity
	ID   string     `json:"id"`
	Type ObjectType `json:"type"` // UAV | MISSILE | THREAT

	// Position
	Lat     float64 `json:"lat"`
	Lon     float64 `json:"lon"`
	Alt     float64 `json:"alt"`
	Heading float64 `json:"heading"`
	Speed   float64 `json:"speed"`

	// Threat classification
	ThreatLevel ThreatLevel `json:"threat_level"`
	Status      string      `json:"status"`

	// UAV specific
	BatteryPct float64 `json:"battery_pct,omitempty"`

	// Missile specific
	TargetLat        float64 `json:"target_lat,omitempty"`
	TargetLon        float64 `json:"target_lon,omitempty"`
	RemainingRangeKm float64 `json:"remaining_range_km,omitempty"`

	Timestamp time.Time `json:"ts"`
}
