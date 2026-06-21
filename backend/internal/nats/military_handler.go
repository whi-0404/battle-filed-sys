package nats

import (
	grpcserver "battlefiled-sys/internal/grpcserver"
	"battlefiled-sys/internal/tracking/model"
	"battlefiled-sys/internal/tracking/service"
	bfpb "battlefiled-sys/proto"
	"context"
	"log"

	"github.com/nats-io/nats.go"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// MilitaryHandler xử lý military events từ NATS "military.position.updated"
type MilitaryHandler struct {
	service *service.TrackingService
	server  *grpcserver.RadarServer
}

func NewMilitaryHandler(svc *service.TrackingService, srv *grpcserver.RadarServer) *MilitaryHandler {
	return &MilitaryHandler{service: svc, server: srv}
}

func (h *MilitaryHandler) HandleMilitaryUpdate(msg *nats.Msg) {
	var event bfpb.MilitaryEvent
	if err := proto.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("[military-handler] proto unmarshal error: %v", err)
		return
	}

	ctx := context.Background()
	objType := protoTypeToModel(event.GetType())
	ts := event.GetTs().AsTime()

	// Upsert aircraft record
	if err := h.service.SaveAircraft(ctx, &model.Aircraft{
		ICAO24:      event.GetId(),
		Callsign:    event.GetId(),
		Type:        objType,
		Status:      model.StatusActive,
		ThreatLevel: model.ThreatLevel(event.GetThreatLevel().String()),
	}); err != nil {
		log.Printf("[military-handler] SaveAircraft error for %s: %v", event.GetId(), err)
	}

	// Upsert tracking position
	if err := h.service.UpdateTrackingCurrent(ctx, &model.Tracking{
		ICAO24:      event.GetId(),
		Lat:         event.GetLat(),
		Lon:         event.GetLon(),
		Alt:         event.GetAlt(),
		Heading:     event.GetHeading(),
		Speed:       event.GetSpeed(),
		LastUpdated: ts,
	}); err != nil {
		log.Printf("[military-handler] UpdateTracking error for %s: %v", event.GetId(), err)
	}

	// Forward lên gRPC RadarServer
	h.server.UpsertObject(&bfpb.RadarObject{
		Id:          event.GetId(),
		Type:        event.GetType(),
		Layer:       bfpb.Layer_MILITARY,
		Callsign:    event.GetId(),
		Lat:         event.GetLat(),
		Lon:         event.GetLon(),
		Alt:         event.GetAlt(),
		Speed:       event.GetSpeed(),
		Heading:     event.GetHeading(),
		ThreatLevel: event.GetThreatLevel(),
		Status:      event.GetStatus(),
		LastUpdated: timestamppb.New(ts),
	})
}

// protoTypeToModel map proto enum → domain model ObjectType
func protoTypeToModel(t bfpb.ObjectType) model.ObjectType {
	switch t {
	case bfpb.ObjectType_UAV:
		return model.ObjUAV
	case bfpb.ObjectType_MISSILE:
		return model.ObjMissile
	case bfpb.ObjectType_THREAT:
		return model.ObjThreat
	default:
		return model.ObjUnknown
	}
}
