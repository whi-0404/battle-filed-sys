package model

import "time"

type MilitaryEvent struct {
	ID   string     `json:"id"`
	Type ObjectType `json:"type"`

	Lat     float64 `json:"lat"`
	Lon     float64 `json:"lon"`
	Alt     float64 `json:"alt"`
	Heading float64 `json:"heading"`
	Speed   float64 `json:"speed"`

	// Threat
	ThreatLevel ThreatLevel    `json:"threat_level"`
	Status      MilitaryStatus `json:"status"`

	// Missile fields
	TargetLat        float64 `json:"target_lat,omitempty"`
	TargetLon        float64 `json:"target_lon,omitempty"`
	RemainingRangeKm float64 `json:"remaining_range_km,omitempty"`

	Timestamp time.Time `json:"ts"`
}
