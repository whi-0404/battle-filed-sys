package grpcserver

import (
	bfpb "battlefiled-sys/proto"
	"log"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const broadcastInterval = 100 * time.Millisecond

type RadarServer struct {
	bfpb.UnimplementedRadarServiceServer

	mu      sync.RWMutex
	objects map[string]*bfpb.RadarObject
}

func NewRadarServer() *RadarServer {
	return &RadarServer{
		objects: make(map[string]*bfpb.RadarObject),
	}
}

func (s *RadarServer) UpsertObject(obj *bfpb.RadarObject) {
	s.mu.Lock()
	s.objects[obj.GetId()] = obj
	s.mu.Unlock()
}

func (s *RadarServer) StreamRadar(
	req *bfpb.StreamRadarRequest,
	stream bfpb.RadarService_StreamRadarServer,
) error {
	log.Printf("[radar-server] Client connected: %v", stream.Context().Value("peer"))

	ticker := time.NewTicker(broadcastInterval)
	defer ticker.Stop()

	for {
		select {
		case <-stream.Context().Done():
			log.Println("[radar-server] Client disconnected")
			return status.Error(codes.Canceled, "client disconnected")

		case <-ticker.C:
			snapshot := s.buildSnapshot()
			if err := stream.Send(snapshot); err != nil {
				log.Printf("[radar-server] Send error: %v", err)
				return err
			}
		}
	}
}

func (s *RadarServer) buildSnapshot() *bfpb.RadarSnapshot {
	s.mu.RLock()
	objects := make([]*bfpb.RadarObject, 0, len(s.objects))
	stats := &bfpb.SnapshotStats{}

	for _, obj := range s.objects {
		objects = append(objects, obj)
		stats.TotalObjects++

		switch obj.GetType() {
		case bfpb.ObjectType_UAV:
			stats.UavCount++
		case bfpb.ObjectType_MISSILE:
			stats.MissileCount++
		case bfpb.ObjectType_THREAT:
			stats.ThreatCount++
			if obj.GetThreatLevel() == bfpb.ThreatLevel_CRITICAL ||
				obj.GetThreatLevel() == bfpb.ThreatLevel_HIGH {
				stats.CriticalThreats++
			}
		default:
			if obj.GetLayer() == bfpb.Layer_CIVIL {
				stats.CivilAircraft++
			}
		}
	}
	s.mu.RUnlock()

	return &bfpb.RadarSnapshot{
		SnapshotAt: timestamppb.Now(),
		Objects:    objects,
		Stats:      stats,
	}
}
