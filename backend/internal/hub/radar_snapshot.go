package hub

import (
	"battlefiled-sys/internal/tracking/model"
	"time"
)

// Layer phân biệt nguồn gốc đối tượng
type Layer string

const (
	LayerCivil    Layer = "CIVIL"
	LayerMilitary Layer = "MILITARY"
)

// RadarObject là representation thống nhất của mọi đối tượng trên radar
type RadarObject struct {
	ID          string           `json:"id"`
	Type        model.ObjectType `json:"type"`    // AIRCRAFT | UAV | MISSILE | THREAT
	Layer       Layer            `json:"layer"`   // CIVIL | MILITARY
	Callsign    string           `json:"callsign,omitempty"`
	Lat         float64          `json:"lat"`
	Lon         float64          `json:"lon"`
	Alt         float64          `json:"alt"`
	Speed       float64          `json:"speed"`
	Heading     float64          `json:"heading"`
	ThreatLevel string           `json:"threat_level,omitempty"`
	Status      string           `json:"status,omitempty"`
	// UAV specific
	BatteryPct float64 `json:"battery_pct,omitempty"`
	// Missile specific
	TargetLat        float64 `json:"target_lat,omitempty"`
	TargetLon        float64 `json:"target_lon,omitempty"`
	RemainingRangeKm float64 `json:"remaining_range_km,omitempty"`
	// Metadata
	LastUpdated time.Time `json:"last_updated"`
}

// SnapshotStats thống kê tổng hợp để hiển thị trên dashboard
type SnapshotStats struct {
	TotalObjects    int `json:"total_objects"`
	CivilAircraft   int `json:"civil_aircraft"`
	UAVCount        int `json:"uav_count"`
	MissileCount    int `json:"missile_count"`
	ThreatCount     int `json:"threat_count"`
	CriticalThreats int `json:"critical_threats"`
}

// RadarSnapshot là payload được gửi qua WebSocket mỗi 100ms
type RadarSnapshot struct {
	SnapshotAt time.Time     `json:"snapshot_at"`
	Objects    []RadarObject `json:"objects"`
	Stats      SnapshotStats `json:"stats"`
}

// BuildSnapshot tổng hợp map objects thành snapshot có thể serialize
func BuildSnapshot(objects map[string]RadarObject) RadarSnapshot {
	list := make([]RadarObject, 0, len(objects))
	stats := SnapshotStats{}

	for _, obj := range objects {
		list = append(list, obj)
		stats.TotalObjects++

		switch obj.Type {
		case model.ObjAircraft:
			stats.CivilAircraft++
		case model.ObjUAV:
			stats.UAVCount++
		case model.ObjMissile:
			stats.MissileCount++
		case model.ObjThreat:
			stats.ThreatCount++
			if obj.ThreatLevel == string(model.ThreatCritical) || obj.ThreatLevel == string(model.ThreatHigh) {
				stats.CriticalThreats++
			}
		}
	}

	return RadarSnapshot{
		SnapshotAt: time.Now(),
		Objects:    list,
		Stats:      stats,
	}
}
