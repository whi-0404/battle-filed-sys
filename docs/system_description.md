# Battle-Field System – Mô tả hệ thống

## 1. Tổng quan

**Battle-Field System** là hệ thống mô phỏng không phận kết hợp hai nguồn dữ liệu song song:

| Layer | Nguồn | Tần suất | Mô tả |
|-------|-------|----------|-------|
| **Civil Aviation** | OpenSky Network (dữ liệu thật) | 3 giây / lần | Máy bay dân sự trong không phận Việt Nam |
| **Military Simulation** | Engine nội bộ (dữ liệu giả lập) | 10–50 ms / lần | UAV, tên lửa và mục tiêu không xác định |

**Luồng dữ liệu tổng quát:**
- Simulator publish sự kiện lên **NATS** dưới dạng **Protobuf binary**
- Backend subscribe NATS, persist vào PostgreSQL, đẩy state vào **gRPC Radar Server**
- Client kết nối gRPC và nhận **RadarSnapshot** stream mỗi **100ms**

---

## 2. Kiến trúc tổng thể

```
┌───────────────────────────────────────────────────────────────┐
│                         SIMULATOR                              │
│                                                                │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │    Civil Layer       │  │     Military Layer           │   │
│  │                      │  │                              │   │
│  │  OpenSky Poller (3s) │  │  UAV Engine    (20ms × 15)  │   │
│  │  → proto.Marshal     │  │  Missile Engine(10ms ×  4)  │   │
│  │    FlightEvent       │  │  Threat Engine (50ms ×  6)  │   │
│  └──────────┬───────────┘  │  → proto.Marshal             │   │
│             │               │    MilitaryEvent             │   │
│             │               └──────────────┬───────────────┘   │
│             │ flight.position.updated (pb)  │ military.position.updated (pb)
└─────────────┼───────────────────────────────┼──────────────────┘
              │           NATS Bus            │
              ▼                               ▼
┌───────────────────────────────────────────────────────────────┐
│                         BACKEND                                │
│                                                                │
│  Civil Handler          Military Handler                       │
│  proto.Unmarshal ──┐    proto.Unmarshal ──┐                   │
│  → persist DB      │    → persist DB      │                   │
│                    └──────────┬───────────┘                   │
│                               │ UpsertObject(*RadarObject)    │
│                               ▼                               │
│                      gRPC RadarServer                          │
│                      map[id]*RadarObject  (sync.RWMutex)       │
│                      ticker 100ms → buildSnapshot()            │
│                               │                               │
│                    :50051 gRPC listen                          │
└───────────────────────────────┼───────────────────────────────┘
                                │ HTTP/2 + Protobuf
                                ▼
                   RadarService.StreamRadar()
                   → stream RadarSnapshot (100ms)
                   → Flutter / grpcurl / any gRPC client
```

---

## 3. Protobuf Schema

**File nguồn:** `proto/battlefield.proto`

Định nghĩa toàn bộ contract của hệ thống, được chia làm 3 nhóm:

### 3.1 NATS Messages (Simulator → Backend)

#### FlightEvent
Payload từ OpenSky Poller, publish lên `flight.position.updated`.

| Field | Type | Mô tả |
|-------|------|-------|
| icao24 | string | Mã ICAO24 của máy bay |
| callsign | string | Hiệu lệnh |
| lat, lon | double | Tọa độ |
| alt | double | Độ cao (mét) |
| speed | double | Tốc độ (knots) |
| heading | double | Hướng bay (0–360°) |
| ts | Timestamp | Thời điểm đo |

#### MilitaryEvent
Payload từ Military Engines, publish lên `military.position.updated`.

| Field | Type | Mô tả |
|-------|------|-------|
| id | string | ID định danh (UAV-001, MSL-001, THR-001) |
| type | ObjectType | UAV / MISSILE / THREAT |
| lat, lon | double | Tọa độ |
| alt | double | Độ cao (mét) |
| speed | double | Tốc độ (knots) |
| heading | double | Hướng bay (0–360°) |
| threat_level | ThreatLevel | LOW / MEDIUM / HIGH / CRITICAL |
| status | string | ACTIVE |
| ts | Timestamp | Thời điểm đo |

#### Enums

```protobuf
enum ObjectType  { UAV=1; MISSILE=2; THREAT=3; }
enum ThreatLevel { LOW=1; MEDIUM=2; HIGH=3; CRITICAL=4; }
enum Layer       { CIVIL=1; MILITARY=2; }
```

### 3.2 gRPC Messages (Backend → Client)

#### RadarObject
Representation thống nhất của mọi đối tượng trên radar.

| Field | Type | Mô tả |
|-------|------|-------|
| id | string | ICAO24 hoặc military ID |
| type | ObjectType | Loại đối tượng |
| layer | Layer | CIVIL hoặc MILITARY |
| callsign | string | Tên hiển thị |
| lat, lon | double | Tọa độ |
| alt, speed, heading | double | Thông số bay |
| threat_level | ThreatLevel | Mức đe dọa |
| status | string | Trạng thái |
| last_updated | Timestamp | Lần cập nhật cuối |

#### RadarSnapshot
Payload gửi về client mỗi 100ms.

```protobuf
message RadarSnapshot {
  Timestamp             snapshot_at = 1;
  repeated RadarObject  objects     = 2;
  SnapshotStats         stats       = 3;
}

message SnapshotStats {
  int32 total_objects    = 1;
  int32 civil_aircraft   = 2;
  int32 uav_count        = 3;
  int32 missile_count    = 4;
  int32 threat_count     = 5;
  int32 critical_threats = 6;
}
```

### 3.3 gRPC Service

```protobuf
service RadarService {
  rpc StreamRadar(StreamRadarRequest) returns (stream RadarSnapshot);
}
```

**Pattern:** Server Streaming – client gửi một request, nhận stream vô hạn snapshot cho đến khi disconnect.

---

## 4. Thành phần chi tiết

### 4.1 Simulator (`simulator/`)

#### Civil Layer

**Files:** `opensky/service/opensky_client.go`, `flight_service.go`

- Poll OpenSky REST API mỗi **3 giây**
- Bounding box: Việt Nam `lamin=8, lomin=102, lamax=24, lomax=110`
- Xác thực Basic Auth (`OPENSKY_USERNAME` / `OPENSKY_PASSWORD`)
- Parse JSON response → `*bfpb.FlightEvent` → `proto.Marshal` → publish NATS

#### Military Layer

3 engine chạy song song, dùng chung hàm `move()` và `NatsPublisher`.

**File shared:** `military/engine/uav_engine.go` chứa `move()` + geo helpers dùng bởi cả 3 engine.

##### UAV Engine — `military/engine/uav_engine.go`

| Thông số | Giá trị |
|----------|---------|
| Số lượng | 15 UAV |
| Tick rate | **20ms** |
| Tốc độ | 80 – 180 knots |
| Độ cao | 500 – 5000 m |
| Threat level | LOW |

##### Missile Engine — `military/engine/missile_engine.go`

| Thông số | Giá trị |
|----------|---------|
| Số lượng | 4 missiles |
| Tick rate | **10ms** |
| Tốc độ | 500 – 900 knots |
| Độ cao | 3000 – 10000 m |
| Threat level | CRITICAL |

##### Threat Engine — `military/engine/threat_engine.go`

| Thông số | Giá trị |
|----------|---------|
| Số lượng | 6 threats |
| Tick rate | **50ms** |
| Tốc độ | 50 – 300 knots |
| Độ cao | 100 – 8000 m |
| Threat level | Phân bổ đều LOW/MEDIUM/HIGH/CRITICAL |

**Cơ chế di chuyển chung `move()`:**
1. `distKm = knotsToKmh(speed) × dt.Hours()`
2. `movePosition(lat, lon, heading, distKm)` — Spherical Earth (haversine)
3. Nếu vị trí mới ra ngoài bbox → đảo `heading + 180°` (bounce)
4. Wobble ngẫu nhiên `±2°` mỗi tick

**Publisher:** `military/publisher/nats_publisher.go`
```
proto.Marshal(*MilitaryEvent) → nc.Publish("military.position.updated", bytes)
```

**Simulator entry point:** `cmd/main.go`
- 4 goroutine: civil poller + UAV engine + missile engine + threat engine
- `context.Context` + `sync.WaitGroup` cho graceful shutdown

---

### 4.2 Backend (`backend/`)

#### Database — PostgreSQL

**Migration 001** — `migrations/001_init_schema.up.sql`:

| Bảng | Mô tả |
|------|-------|
| `aircraft` | Định danh: `icao24`, `callsign`, `type`, `status` |
| `tracking` | Vị trí hiện tại — UPSERT, 1 row/object |
| `track_history` | Lịch sử — append-only, index `(icao24, snapshot_at DESC)` |

**Migration 002** — `migrations/002_add_military_support.up.sql`:

| Thay đổi | Mô tả |
|----------|-------|
| `aircraft.threat_level` | Cột mới `VARCHAR(20)`, default `LOW` |
| `radar_snapshot` | Bảng lưu snapshot gần nhất |
| Indexes | `idx_aircraft_type_military`, `idx_aircraft_threat_level` |

#### NATS Handlers

**Civil Handler** — `internal/nats/tracking_handler.go`
- Subscribe: `flight.position.updated`
- `proto.Unmarshal` → `*bfpb.FlightEvent`
- SaveAircraft → UpdateTrackingCurrent → SaveTrackingHistory → `RadarServer.UpsertObject`

**Military Handler** — `internal/nats/military_handler.go`
- Subscribe: `military.position.updated`
- `proto.Unmarshal` → `*bfpb.MilitaryEvent`
- SaveAircraft → UpdateTrackingCurrent → `RadarServer.UpsertObject`
- DB error **không block** việc forward lên RadarServer

#### gRPC Radar Server — `internal/grpcserver/radar_server.go`

```
RadarServer
 ├── objects: map[id]*RadarObject   ← shared state (sync.RWMutex)
 └── implement RadarServiceServer

UpsertObject(*RadarObject)          ← gọi từ NATS handlers (thread-safe)

StreamRadar(req, stream):
  ticker 100ms:
    buildSnapshot() → stream.Send(*RadarSnapshot)
  stream.Context().Done():
    return → gRPC tự dọn dẹp connection
```

- Mỗi client gọi `StreamRadar()` → một goroutine riêng chạy loop
- `buildSnapshot()` đọc shared map với `RLock`
- Không cần broadcast channel — mỗi stream tự đọc state

#### gRPC Server Setup — `cmd/main.go`

```go
grpcSrv := grpc.NewServer()
bfpb.RegisterRadarServiceServer(grpcSrv, radarServer)
reflection.Register(grpcSrv)  // enable grpcurl testing
grpcSrv.Serve(lis)            // :50051
```

---

## 5. NATS Topics

| Topic | Publisher | Subscriber | Format | Tần suất |
|-------|-----------|------------|--------|----------|
| `flight.position.updated` | OpenSky Poller | Civil Handler | Protobuf `FlightEvent` | ~3s |
| `military.position.updated` | UAV / Missile / Threat Engine | Military Handler | Protobuf `MilitaryEvent` | 10–50ms |

---

## 6. gRPC Stream Output

**Endpoint:** `localhost:50051` — `battlefield.RadarService/StreamRadar`

Client gọi một lần, nhận stream vô tận mỗi **100ms**:

```json
// Dạng JSON để dễ đọc – thực tế là Protobuf binary
{
  "snapshot_at": "2026-06-21T15:50:00.100Z",
  "objects": [
    {
      "id":          "3c6586",
      "type":        "OBJECT_TYPE_UNSPECIFIED",
      "layer":       "CIVIL",
      "callsign":    "VN123",
      "lat":         10.823,
      "lon":         106.629,
      "alt":         10668.0,
      "speed":       450.2,
      "heading":     275.0,
      "last_updated": "..."
    },
    {
      "id":           "UAV-001",
      "type":         "UAV",
      "layer":        "MILITARY",
      "callsign":     "UAV-001",
      "lat":          16.045,
      "lon":          108.21,
      "alt":          2500.0,
      "speed":        120.0,
      "heading":      45.3,
      "threat_level": "LOW",
      "status":       "ACTIVE",
      "last_updated": "..."
    },
    {
      "id":           "MSL-001",
      "type":         "MISSILE",
      "layer":        "MILITARY",
      "lat":          14.12,
      "lon":          107.80,
      "alt":          8000.0,
      "speed":        700.0,
      "heading":      180.0,
      "threat_level": "CRITICAL",
      "status":       "ACTIVE",
      "last_updated": "..."
    }
  ],
  "stats": {
    "total_objects":    25,
    "civil_aircraft":    4,
    "uav_count":        15,
    "missile_count":     4,
    "threat_count":      6,
    "critical_threats":  4
  }
}
```

---

## 7. Cấu trúc thư mục

```
battle-filed-sys/
│
├── proto/
│   └── battlefield.proto               Schema duy nhất: messages + enums + service
│
├── simulator/
│   ├── cmd/main.go                     Entry: 4 goroutines + graceful shutdown
│   ├── go.mod                          module: simulator
│   ├── proto/
│   │   └── battlefield.pb.go           [GENERATED] messages only
│   ├── opensky/service/
│   │   ├── opensky_client.go           HTTP client + Basic Auth
│   │   └── flight_service.go           Poll → parse → proto.Marshal → NATS
│   └── military/
│       ├── engine/
│       │   ├── uav_engine.go           UAV 20ms + move() + geo helpers (shared)
│       │   ├── missile_engine.go       Missile 10ms
│       │   └── threat_engine.go        Threat 50ms
│       └── publisher/
│           └── nats_publisher.go       proto.Marshal → nc.Publish()
│
├── backend/
│   ├── cmd/main.go                     Entry: DB + NATS + gRPC server
│   ├── go.mod                          module: battlefiled-sys
│   ├── docker-compose.yml              postgres:5432 + nats:4222
│   ├── config/config.go                Load env vars
│   ├── db/postgres.go                  sqlx connect + migrate
│   ├── proto/
│   │   ├── battlefield.pb.go           [GENERATED] messages
│   │   └── battlefield_grpc.pb.go      [GENERATED] RadarServiceServer interface
│   ├── migrations/
│   │   ├── 001_init_schema.up/down.sql
│   │   └── 002_add_military_support.up/down.sql
│   └── internal/
│       ├── grpcserver/
│       │   └── radar_server.go         RadarServiceServer impl + shared state
│       ├── nats/
│       │   ├── subscriber.go           SubscribeTracking() + SubscribeMilitary()
│       │   ├── tracking_handler.go     Civil: unmarshal pb → DB → RadarServer
│       │   └── military_handler.go     Military: unmarshal pb → DB → RadarServer
│       └── tracking/
│           ├── model/
│           │   ├── aircarft.go         Aircraft, ObjectType, ThreatLevel
│           │   ├── tracking.go         Tracking (current position)
│           │   └── tracking_history.go TrackingHistory
│           ├── repository/
│           │   ├── tracking_repository.go   Interface
│           │   └── postgres_repository.go   SQL impl
│           └── service/
│               └── tracking_service.go
│
└── client/                             (Placeholder – Flutter)
    ├── main.dart
    ├── models/aircraft.dart
    ├── services/api_service.dart
    └── features/
        ├── map/
        ├── dashboard/
        └── tracking/
```

---

## 8. Environment Variables

### Simulator (`.env`)

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `NATS_URL` | `nats://localhost:4222` | NATS server |
| `OPENSKY_USERNAME` | _(trống)_ | OpenSky account (anonymous nếu trống) |
| `OPENSKY_PASSWORD` | _(trống)_ | OpenSky password |

### Backend (`.env`)

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `NATS_URL` | `nats://localhost:4222` | NATS server |
| `GRPC_PORT` | `50051` | gRPC server port |
| `DB_HOST` | – | PostgreSQL host |
| `DB_PORT` | – | PostgreSQL port |
| `DB_USER` | – | PostgreSQL user |
| `DB_PASSWORD` | – | PostgreSQL password |
| `DB_NAME` | – | PostgreSQL database name |

---

## 9. Hướng dẫn chạy

```bash
# 1. Khởi động PostgreSQL + NATS
cd backend && docker-compose up -d

# 2. Chạy Backend
cd backend && go run ./cmd/
# Log: gRPC server listening on :50051

# 3. Chạy Simulator (terminal khác)
cd simulator && go run ./cmd/
# Log: UAV/Missile/Threat engines started + OpenSky polling

# 4. Test stream bằng grpcurl
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50051 battlefield.RadarService/StreamRadar
```

---

## 10. Luồng dữ liệu chi tiết

```
OpenSky API (3s)
    │ HTTP GET (Basic Auth)
    ▼ JSON response
flight_service.go
    │ parse → *bfpb.FlightEvent
    │ proto.Marshal(event)
    │ nc.Publish("flight.position.updated", bytes)
    ▼
  NATS ──► tracking_handler.go
              │ proto.Unmarshal(msg.Data, &FlightEvent)
              ├── SaveAircraft(ctx)          → DB: aircraft UPSERT
              ├── UpdateTrackingCurrent(ctx) → DB: tracking UPSERT
              ├── SaveTrackingHistory(ctx)   → DB: track_history INSERT
              └── RadarServer.UpsertObject(*RadarObject{layer:CIVIL})

UAV/Missile/Threat Engine (10–50ms)
    │ build *bfpb.MilitaryEvent
    │ proto.Marshal(event)
    │ nc.Publish("military.position.updated", bytes)
    ▼
  NATS ──► military_handler.go
              │ proto.Unmarshal(msg.Data, &MilitaryEvent)
              ├── SaveAircraft(ctx)          → DB: aircraft UPSERT
              ├── UpdateTrackingCurrent(ctx) → DB: tracking UPSERT
              └── RadarServer.UpsertObject(*RadarObject{layer:MILITARY})

RadarServer (per client stream, 100ms ticker)
    │ buildSnapshot() → RLock → copy objects → RUnlock
    │ stream.Send(*RadarSnapshot)  [Protobuf binary over HTTP/2]
    ▼
gRPC Client (Flutter / grpcurl)
```

---

## 11. Thiết kế concurrency

| Component | Goroutine | Cơ chế đồng bộ |
|-----------|-----------|----------------|
| Civil Poller | 1 (ticker 3s) | Không cần |
| UAV Engine | 1 (ticker 20ms) | Không cần |
| Missile Engine | 1 (ticker 10ms) | Không cần |
| Threat Engine | 1 (ticker 50ms) | Không cần |
| NATS Callbacks | N (NATS internal pool) | `RadarServer.mu` RWMutex |
| StreamRadar | 1 per client (ticker 100ms) | `RadarServer.mu` RLock |
| gRPC Server | 1 + N per client | gRPC internal |

> NATS handlers là **writers** → dùng `Lock()`.
> StreamRadar goroutines là **readers** → dùng `RLock()` song song.
> Không bao giờ block lẫn nhau trong cùng một phase.

---

## 12. Tái generate Protobuf

Khi sửa `proto/battlefield.proto`, chạy lại:

```powershell
$protoc        = "...\protoc.exe"
$protocGenGo   = "$env:GOPATH\bin\protoc-gen-go.exe"
$protocGenGrpc = "$env:GOPATH\bin\protoc-gen-go-grpc.exe"

# Backend (messages + gRPC stubs)
& $protoc `
  --plugin="protoc-gen-go=$protocGenGo" `
  --plugin="protoc-gen-go-grpc=$protocGenGrpc" `
  --go_out="backend/proto"      --go_opt=paths=source_relative `
  --go-grpc_out="backend/proto" --go-grpc_opt=paths=source_relative `
  --proto_path="proto" "proto/battlefield.proto"

# Simulator (messages only)
& $protoc `
  --plugin="protoc-gen-go=$protocGenGo" `
  --go_out="simulator/proto" --go_opt=paths=source_relative `
  --proto_path="proto" "proto/battlefield.proto"
```

**Flutter client** (khi cần):
```bash
dart pub global activate protoc_plugin
protoc --dart_out=grpc:lib/proto proto/battlefield.proto
```
