package model

import (
	"time"
)

type TrackingHistory struct {
	ID         string    `json:"id" db:"id"`
	ICAO24     string    `json:"icao24" db:"icao24"`
	Lat        float64   `json:"lat" db:"latitude"`
	Lon        float64   `json:"lon" db:"longitude"`
	Alt        float64   `json:"alt" db:"altitude"`
	Heading    float64   `json:"heading" db:"heading"`
	Speed      float64   `json:"speed" db:"speed"`
	SnapshotAt time.Time `json:"snapshot_at" db:"snapshot_at"`
}
