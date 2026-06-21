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

// TrackingHandler xử lý civil aviation events từ NATS "flight.position.updated"
type TrackingHandler struct {
	service *service.TrackingService
	server  *grpcserver.RadarServer
}

func NewTrackingHandler(svc *service.TrackingService, srv *grpcserver.RadarServer) *TrackingHandler {
	return &TrackingHandler{service: svc, server: srv}
}

func (h *TrackingHandler) HandlePositionUpdate(msg *nats.Msg) {
	var event bfpb.FlightEvent
	if err := proto.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("[civil-handler] proto unmarshal error: %v", err)
		return
	}

	ctx := context.Background()
	ts := event.GetTs().AsTime()

	// Upsert aircraft
	aircraft := model.NewAircraft(event.GetCallsign(), model.ObjAircraft)
	aircraft.ICAO24 = event.GetIcao24()
	aircraft.Callsign = event.GetCallsign()
	if err := h.service.SaveAircraft(ctx, aircraft); err != nil {
		log.Printf("[civil-handler] SaveAircraft error: %v", err)
	}

	// Upsert current tracking
	if err := h.service.UpdateTrackingCurrent(ctx, &model.Tracking{
		ICAO24:      event.GetIcao24(),
		Lat:         event.GetLat(),
		Lon:         event.GetLon(),
		Alt:         event.GetAlt(),
		Heading:     event.GetHeading(),
		Speed:       event.GetSpeed(),
		LastUpdated: ts,
	}); err != nil {
		log.Printf("[civil-handler] UpdateTracking error: %v", err)
	}

	// Insert tracking history
	if err := h.service.SaveTrackingHistory(ctx, &model.TrackingHistory{
		ICAO24:     event.GetIcao24(),
		Lat:        event.GetLat(),
		Lon:        event.GetLon(),
		Alt:        event.GetAlt(),
		Heading:    event.GetHeading(),
		Speed:      event.GetSpeed(),
		SnapshotAt: ts,
	}); err != nil {
		log.Printf("[civil-handler] SaveTrackingHistory error: %v", err)
	}

	// Forward lên gRPC RadarServer
	h.server.UpsertObject(&bfpb.RadarObject{
		Id:          event.GetIcao24(),
		Type:        bfpb.ObjectType_OBJECT_TYPE_UNSPECIFIED, // aircraft dùng layer để phân biệt
		Layer:       bfpb.Layer_CIVIL,
		Callsign:    event.GetCallsign(),
		Lat:         event.GetLat(),
		Lon:         event.GetLon(),
		Alt:         event.GetAlt(),
		Speed:       event.GetSpeed(),
		Heading:     event.GetHeading(),
		LastUpdated: timestamppb.New(ts),
	})

	log.Printf("[civil-handler] Processed: %s (%s)", event.GetIcao24(), event.GetCallsign())
}
