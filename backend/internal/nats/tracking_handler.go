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

type TrackingHandler struct {
	service *service.TrackingService
	hub     *hub.Hub
}

type FlightEvent struct {
	ICAO24    string    `json:"icao24"`
	Callsign  string    `json:"callsign"`
	Lat       float64   `json:"lat"`
	Lon       float64   `json:"lon"`
	Alt       float64   `json:"alt"`
	Speed     float64   `json:"speed"`
	Heading   float64   `json:"heading"`
	Timestamp time.Time `json:"ts"`
}

func NewTrackingHandler(service *service.TrackingService, h *hub.Hub) *TrackingHandler {
	return &TrackingHandler{
		service: service,
		hub:     h,
	}
}

func (h *TrackingHandler) HandlePositionUpdate(msg *nats.Msg) {
	var event FlightEvent

	err := json.Unmarshal(
		msg.Data,
		&event,
	)

	if err != nil {
		log.Printf("Error unmarshalling flight event: %v", err)
		return
	}

	aircraft := model.NewAircraft(event.Callsign, model.ObjAircraft)
	aircraft.ICAO24 = event.ICAO24
	aircraft.Callsign = event.Callsign

	err = h.service.SaveAircraft(context.Background(), aircraft)
	if err != nil {
		log.Printf("Error saving aircraft: %v", err)
	}

	tracking := mapFlightEventToTracking(event)

	err = h.service.UpdateTrackingCurrent(context.Background(), &tracking)
	if err != nil {
		log.Printf("Error updating tracking: %v", err)
	}

	trackingHistory := mapFlightEventToTrackingHistory(event)
	err = h.service.SaveTrackingHistory(context.Background(), &trackingHistory)
	if err != nil {
		log.Printf("Error saving tracking history: %v", err)
		return
	}

	log.Printf("Saved tracking data for Flight %s", event.ICAO24)

	// Forward lên WebSocket Hub dưới dạng RadarObject
	h.hub.UpsertObject(hub.RadarObject{
		ID:          event.ICAO24,
		Type:        model.ObjAircraft,
		Layer:       hub.LayerCivil,
		Callsign:    event.Callsign,
		Lat:         event.Lat,
		Lon:         event.Lon,
		Alt:         event.Alt,
		Speed:       event.Speed,
		Heading:     event.Heading,
		LastUpdated: event.Timestamp,
	})
}

func mapFlightEventToTracking(
	event FlightEvent,
) model.Tracking {
	return model.Tracking{
		ICAO24:      event.ICAO24,
		Lat:         event.Lat,
		Lon:         event.Lon,
		Alt:         event.Alt,
		Heading:     event.Heading,
		Speed:       event.Speed,
		LastUpdated: event.Timestamp,
	}
}

func mapFlightEventToTrackingHistory(
	event FlightEvent,
) model.TrackingHistory {
	return model.TrackingHistory{
		ICAO24:     event.ICAO24,
		Lat:        event.Lat,
		Lon:        event.Lon,
		Alt:        event.Alt,
		Heading:    event.Heading,
		Speed:      event.Speed,
		SnapshotAt: event.Timestamp,
	}
}
