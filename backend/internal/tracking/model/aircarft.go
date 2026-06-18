package model

import (
	"time"

	"github.com/google/uuid"
)

type ObjectType string

const (
	ObjAircraft ObjectType = "AIRCRAFT"
	ObjUAV      ObjectType = "UAV"
	ObjUnknown  ObjectType = "UNKNOWN"
)

type ObjectStatus string

const (
	StatusActive    ObjectStatus = "ACTIVE"
	StatusInactive  ObjectStatus = "INACTIVE"
	StatusLost      ObjectStatus = "LOST"
	StatusDestroyed ObjectStatus = "DESTROYED"
)

type Aircraft struct {
	ID string `json:"id" db:"id"`

	Callsign string `json:"callsign" db:"callsign"`

	ICAO24 string `json:"icao24" db:"icao24"`

	Type ObjectType `json:"type" db:"type"`

	Status ObjectStatus `json:"status" db:"status"`

	CreatedAt time.Time `json:"created_at" db:"created_at"`

	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

func NewAircraft(callsign string, objType ObjectType) *Aircraft {
	return &Aircraft{
		ID:        uuid.NewString(),
		Type:      objType,
		Status:    StatusActive,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}
