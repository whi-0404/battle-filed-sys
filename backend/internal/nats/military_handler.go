package nats

import (
	grpcserver "battlefiled-sys/internal/grpcserver"
	"battlefiled-sys/internal/tracking/model"
	"battlefiled-sys/internal/tracking/service"
	bfpb "battlefiled-sys/proto"
	"context"
	"log"
	"time"

	"github.com/nats-io/nats.go"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// MilitaryHandler xử lý military events từ NATS "military.position.updated"
type MilitaryHandler struct {
	service *service.TrackingService
	server  *grpcserver.RadarServer

	aircraftChan chan *model.Aircraft
	trackingChan chan *model.Tracking
}

func NewMilitaryHandler(svc *service.TrackingService, srv *grpcserver.RadarServer) *MilitaryHandler {
	h := &MilitaryHandler{
		service:      svc,
		server:       srv,
		aircraftChan: make(chan *model.Aircraft, 100000),
		trackingChan: make(chan *model.Tracking, 100000),
	}
	go h.startBatchWorker()
	return h
}

func (h *MilitaryHandler) startBatchWorker() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	aircraftBatch := make(map[string]*model.Aircraft)
	trackingBatch := make(map[string]*model.Tracking)

	for {
		select {
		case a := <-h.aircraftChan:
			aircraftBatch[a.ICAO24] = a
		case t := <-h.trackingChan:
			trackingBatch[t.ICAO24] = t
		case <-ticker.C:
			if len(aircraftBatch) > 0 {
				list := make([]*model.Aircraft, 0, len(aircraftBatch))
				for _, a := range aircraftBatch {
					list = append(list, a)
				}
				if err := h.service.BulkSaveAircraft(context.Background(), list); err != nil {
					log.Printf("[military-handler] BulkSaveAircraft error: %v", err)
				}
				aircraftBatch = make(map[string]*model.Aircraft)
			}

			if len(trackingBatch) > 0 {
				list := make([]*model.Tracking, 0, len(trackingBatch))
				for _, t := range trackingBatch {
					list = append(list, t)
				}
				if err := h.service.BulkUpdateCurrentTrack(context.Background(), list); err != nil {
					log.Printf("[military-handler] BulkUpdateTracking error: %v", err)
				}
				trackingBatch = make(map[string]*model.Tracking)
			}
		}
	}
}

func (h *MilitaryHandler) HandleMilitaryUpdate(msg *nats.Msg) {
	var event bfpb.MilitaryEvent
	if err := proto.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("[military-handler] proto unmarshal error: %v", err)
		return
	}

	objType := protoTypeToModel(event.GetType())
	ts := event.GetTs().AsTime()

	// Push to batch channel (non-blocking if possible, but large buffer used)
	select {
	case h.aircraftChan <- &model.Aircraft{
		ICAO24:      event.GetId(),
		Callsign:    event.GetId(),
		Type:        objType,
		Status:      model.StatusActive,
		ThreatLevel: model.ThreatLevel(event.GetThreatLevel().String()),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}:
	default:
		// Queue full, skip DB update for this tick
	}

	select {
	case h.trackingChan <- &model.Tracking{
		ICAO24:      event.GetId(),
		Lat:         event.GetLat(),
		Lon:         event.GetLon(),
		Alt:         event.GetAlt(),
		Heading:     event.GetHeading(),
		Speed:       event.GetSpeed(),
		LastUpdated: ts,
	}:
	default:
		// Queue full, skip DB update for this tick
	}

	// Forward lên gRPC RadarServer trực tiếp qua memory (real-time tuyệt đối)
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
