package model

import (
	"time"
)

type Tracking struct {
	ObjectID    string    `json:"object_id" db:"object_id"`
	Lat         float64   `json:"lat" db:"latitude"`
	Lon         float64   `json:"lon" db:"longitude"`
	Alt         float64   `json:"alt" db:"altitude"`
	Heading     float64   `json:"heading" db:"heading"`
	Speed       float64   `json:"speed" db:"speed"`
	LastUpdated time.Time `json:"last_updated" db:"last_updated"`
}
