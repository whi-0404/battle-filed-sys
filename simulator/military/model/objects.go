package model

// ObjectType phân loại các đối tượng trong hệ thống
type ObjectType string

const (
	ObjUAV     ObjectType = "UAV"
	ObjMissile ObjectType = "MISSILE"
	ObjThreat  ObjectType = "THREAT"
)

// ThreatLevel mức độ nguy hiểm
type ThreatLevel string

const (
	ThreatLow      ThreatLevel = "LOW"
	ThreatMedium   ThreatLevel = "MEDIUM"
	ThreatHigh     ThreatLevel = "HIGH"
	ThreatCritical ThreatLevel = "CRITICAL"
)

// MilitaryStatus trạng thái hoạt động
type MilitaryStatus string

const (
	StatusActive    MilitaryStatus = "ACTIVE"
	StatusReturning MilitaryStatus = "RETURNING" // UAV returning to base
	StatusTerminal  MilitaryStatus = "TERMINAL"  // Missile on final approach
	StatusLost      MilitaryStatus = "LOST"
	StatusDestroyed MilitaryStatus = "DESTROYED"
)

// MilitaryObject đối tượng quân sự trong simulation
type MilitaryObject struct {
	ID     string
	Type   ObjectType
	Status MilitaryStatus

	// Vị trí hiện tại
	Lat     float64
	Lon     float64
	Alt     float64 // mét
	Heading float64 // độ, 0-360
	Speed   float64 // knots

	// UAV specific
	BatteryPct float64 // 0-100, chỉ dùng cho UAV
	BaseLat    float64 // vị trí căn cứ
	BaseLon    float64

	// Missile specific
	TargetLat        float64
	TargetLon        float64
	RemainingRangeKm float64

	// Threat specific
	ThreatLevel  ThreatLevel
	ThreatExpiry int64 // unix timestamp khi threat biến mất
}
