package model

import "time"

// MilitaryEvent là payload được publish lên NATS khi có cập nhật vị trí quân sự
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

	// Threat
	ThreatLevel ThreatLevel    `json:"threat_level"`
	Status      MilitaryStatus `json:"status"`

	// UAV fields (omitempty để không tốn bandwidth khi không dùng)
	BatteryPct float64 `json:"battery_pct,omitempty"`

	// Missile fields
	TargetLat        float64 `json:"target_lat,omitempty"`
	TargetLon        float64 `json:"target_lon,omitempty"`
	RemainingRangeKm float64 `json:"remaining_range_km,omitempty"`

	Timestamp time.Time `json:"ts"`
}
