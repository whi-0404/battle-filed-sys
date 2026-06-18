package engine

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/rand"
	"simulator/military/model"
	"simulator/military/publisher"
	"time"
)

const (
	uavTickInterval = 20 * time.Millisecond
	uavCount        = 15

	// Bounding box Việt Nam + vùng lân cận (để phù hợp với OpenSky bbox)
	uavLatMin = 9.0
	uavLatMax = 23.0
	uavLonMin = 102.5
	uavLonMax = 109.5

	uavAltMin   = 500.0  // mét
	uavAltMax   = 5000.0 // mét
	uavSpeedMin = 80.0   // knots
	uavSpeedMax = 180.0  // knots

	batteryDrainPerTick = 0.00005 // drain mỗi 20ms tick
)

// UAVEngine quản lý toàn bộ UAV objects và update vị trí theo goroutine pool
type UAVEngine struct {
	pub  *publisher.NatsPublisher
	uavs []*model.MilitaryObject
}

func NewUAVEngine(pub *publisher.NatsPublisher) *UAVEngine {
	e := &UAVEngine{pub: pub}
	e.spawnUAVs()
	return e
}

// spawnUAVs khởi tạo N UAVs với vị trí và thông số ngẫu nhiên
func (e *UAVEngine) spawnUAVs() {
	e.uavs = make([]*model.MilitaryObject, uavCount)
	for i := 0; i < uavCount; i++ {
		lat := uavLatMin + rand.Float64()*(uavLatMax-uavLatMin)
		lon := uavLonMin + rand.Float64()*(uavLonMax-uavLonMin)
		e.uavs[i] = &model.MilitaryObject{
			ID:          fmt.Sprintf("UAV-%03d", i+1),
			Type:        model.ObjUAV,
			Status:      model.StatusActive,
			Lat:         lat,
			Lon:         lon,
			Alt:         uavAltMin + rand.Float64()*(uavAltMax-uavAltMin),
			Heading:     rand.Float64() * 360,
			Speed:       uavSpeedMin + rand.Float64()*(uavSpeedMax-uavSpeedMin),
			BatteryPct:  70 + rand.Float64()*30, // bắt đầu với 70-100%
			BaseLat:     lat,
			BaseLon:     lon,
			ThreatLevel: model.ThreatLow,
		}
	}
	log.Printf("[uav-engine] Spawned %d UAVs", uavCount)
}

// Run bắt đầu engine loop, block cho đến khi ctx cancel
func (e *UAVEngine) Run(ctx context.Context) {
	ticker := time.NewTicker(uavTickInterval)
	defer ticker.Stop()

	log.Println("[uav-engine] Started – tick every", uavTickInterval)

	for {
		select {
		case <-ctx.Done():
			log.Println("[uav-engine] Shutting down")
			return
		case <-ticker.C:
			for _, uav := range e.uavs {
				e.updateUAV(uav)
				e.pub.Publish(toEvent(uav))
			}
		}
	}
}

// updateUAV cập nhật vị trí và trạng thái của một UAV
func (e *UAVEngine) updateUAV(uav *model.MilitaryObject) {
	dtHours := uavTickInterval.Hours()

	// Battery drain
	uav.BatteryPct -= batteryDrainPerTick
	if uav.BatteryPct < 0 {
		uav.BatteryPct = 0
	}

	// Nếu pin dưới 20% → return to base
	if uav.BatteryPct < 20 && uav.Status == model.StatusActive {
		uav.Status = model.StatusReturning
		// Hướng về base
		uav.Heading = bearingTo(uav.Lat, uav.Lon, uav.BaseLat, uav.BaseLon)
		log.Printf("[uav-engine] %s low battery (%.1f%%), returning to base", uav.ID, uav.BatteryPct)
	}

	// Nếu đã về đến base → recharge và gửi lại
	if uav.Status == model.StatusReturning {
		distKm := haversine(uav.Lat, uav.Lon, uav.BaseLat, uav.BaseLon)
		if distKm < 0.5 {
			// Recharge tại chỗ
			uav.BatteryPct = 100
			uav.Status = model.StatusActive
			uav.Heading = rand.Float64() * 360 // patrol hướng mới
			log.Printf("[uav-engine] %s recharged, resuming patrol", uav.ID)
		}
	}

	// Cập nhật vị trí dựa trên heading và speed
	distKm := knotsToKmh(uav.Speed) * dtHours
	newLat, newLon := movePosition(uav.Lat, uav.Lon, uav.Heading, distKm)

	// Nếi ra ngoài bbox → đổi hướng ngược lại
	if newLat < uavLatMin || newLat > uavLatMax || newLon < uavLonMin || newLon > uavLonMax {
		uav.Heading = math.Mod(uav.Heading+180, 360)
		newLat, newLon = movePosition(uav.Lat, uav.Lon, uav.Heading, distKm)
	}

	uav.Lat = newLat
	uav.Lon = newLon

	// Random wobble heading ±2° mỗi tick để chuyển động tự nhiên hơn
	if uav.Status == model.StatusActive {
		uav.Heading = math.Mod(uav.Heading+(rand.Float64()*4-2)+360, 360)
	}
}

// toEvent convert MilitaryObject → MilitaryEvent để publish
func toEvent(obj *model.MilitaryObject) model.MilitaryEvent {
	return model.MilitaryEvent{
		ID:          obj.ID,
		Type:        obj.Type,
		Lat:         obj.Lat,
		Lon:         obj.Lon,
		Alt:         obj.Alt,
		Heading:     obj.Heading,
		Speed:       obj.Speed,
		ThreatLevel: obj.ThreatLevel,
		Status:      obj.Status,
		BatteryPct:  obj.BatteryPct,
		TargetLat:   obj.TargetLat,
		TargetLon:   obj.TargetLon,
		Timestamp:   time.Now(),
	}
}

// ─── Geo math helpers ────────────────────────────────────────────

const earthRadiusKm = 6371.0

func deg2rad(d float64) float64 { return d * math.Pi / 180 }
func rad2deg(r float64) float64 { return r * 180 / math.Pi }

// haversine trả về khoảng cách km giữa 2 điểm
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	dLat := deg2rad(lat2 - lat1)
	dLon := deg2rad(lon2 - lon1)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(deg2rad(lat1))*math.Cos(deg2rad(lat2))*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	return earthRadiusKm * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

// bearingTo tính heading từ điểm 1 đến điểm 2 (độ)
func bearingTo(lat1, lon1, lat2, lon2 float64) float64 {
	dLon := deg2rad(lon2 - lon1)
	y := math.Sin(dLon) * math.Cos(deg2rad(lat2))
	x := math.Cos(deg2rad(lat1))*math.Sin(deg2rad(lat2)) -
		math.Sin(deg2rad(lat1))*math.Cos(deg2rad(lat2))*math.Cos(dLon)
	return math.Mod(rad2deg(math.Atan2(y, x))+360, 360)
}

// movePosition dịch chuyển điểm theo heading (độ) và khoảng cách (km)
func movePosition(lat, lon, headingDeg, distKm float64) (float64, float64) {
	angDist := distKm / earthRadiusKm
	headingRad := deg2rad(headingDeg)
	lat1 := deg2rad(lat)
	lon1 := deg2rad(lon)

	lat2 := math.Asin(math.Sin(lat1)*math.Cos(angDist) +
		math.Cos(lat1)*math.Sin(angDist)*math.Cos(headingRad))
	lon2 := lon1 + math.Atan2(
		math.Sin(headingRad)*math.Sin(angDist)*math.Cos(lat1),
		math.Cos(angDist)-math.Sin(lat1)*math.Sin(lat2),
	)
	return rad2deg(lat2), rad2deg(lon2)
}

func knotsToKmh(knots float64) float64 { return knots * 1.852 }
