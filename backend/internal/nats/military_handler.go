package nats

import (
	"battlefiled-sys/internal/hub"
	"battlefiled-sys/internal/tracking/model"
	"battlefiled-sys/internal/tracking/service"
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/nats-io/nats.go"
)

// MilitaryHandler xử lý events từ NATS subject "military.position.updated"
type MilitaryHandler struct {
	service *service.TrackingService
	hub     *hub.Hub
}

func NewMilitaryHandler(svc *service.TrackingService, h *hub.Hub) *MilitaryHandler {
	return &MilitaryHandler{service: svc, hub: h}
}

// HandleMilitaryUpdate xử lý mỗi military event:
// 1. Persist aircraft record vào DB
// 2. Upsert tracking position
// 3. Forward đến WebSocket Hub
func (h *MilitaryHandler) HandleMilitaryUpdate(msg *nats.Msg) {
	var event model.MilitaryEvent

	if err := json.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("[military-handler] unmarshal error: %v", err)
		return
	}

	ctx := context.Background()

	// 1. Upsert aircraft record (dùng event.ID làm icao24 cho military objects)
	aircraft := &model.Aircraft{
		ICAO24:      event.ID,
		Callsign:    event.ID, // military objects dùng ID làm callsign
		Type:        event.Type,
		Status:      model.StatusActive,
		ThreatLevel: event.ThreatLevel,
		UpdatedAt:   time.Now(),
	}

	if err := h.service.SaveAircraft(ctx, aircraft); err != nil {
		log.Printf("[military-handler] SaveAircraft error for %s: %v", event.ID, err)
		// Không return – vẫn tiếp tục forward lên hub
	}

	// 2. Upsert tracking position
	tracking := &model.Tracking{
		ICAO24:      event.ID,
		Lat:         event.Lat,
		Lon:         event.Lon,
		Alt:         event.Alt,
		Heading:     event.Heading,
		Speed:       event.Speed,
		LastUpdated: event.Timestamp,
	}

	if err := h.service.UpdateTrackingCurrent(ctx, tracking); err != nil {
		log.Printf("[military-handler] UpdateTracking error for %s: %v", event.ID, err)
	}

	// 3. Forward lên WebSocket Hub
	radarObj := hub.RadarObject{
		ID:               event.ID,
		Type:             event.Type,
		Layer:            hub.LayerMilitary,
		Callsign:         event.ID,
		Lat:              event.Lat,
		Lon:              event.Lon,
		Alt:              event.Alt,
		Speed:            event.Speed,
		Heading:          event.Heading,
		ThreatLevel:      string(event.ThreatLevel),
		Status:           event.Status,
		BatteryPct:       event.BatteryPct,
		TargetLat:        event.TargetLat,
		TargetLon:        event.TargetLon,
		RemainingRangeKm: event.RemainingRangeKm,
		LastUpdated:      event.Timestamp,
	}

	h.hub.UpsertObject(radarObj)
}
