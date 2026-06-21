# Phân tích chuyên sâu Backend: Protobuf, gRPC và Database Layer

Tài liệu này tập trung mổ xẻ các khía cạnh kỹ thuật cốt lõi trong hệ thống Backend của **Battlefield Radar**, bao gồm cách định nghĩa dữ liệu bằng Protobuf, luồng gRPC Streaming và tầng lưu trữ dữ liệu (Database Layer).

---

## 1. Protobuf (Protocol Buffers) - Xương sống giao tiếp

Protobuf đóng vai trò là "ngôn ngữ chung" (Source of Truth) cho toàn bộ hệ thống. Với bài toán xử lý hàng nghìn object bay mỗi giây, HTTP/JSON truyền thống thường gặp nút thắt (bottleneck) về kích thước payload và tốc độ parse. Protobuf giải quyết triệt để vấn đề này bằng định dạng nhị phân (Binary Serialization).

### 1.1. Biên dịch chéo đa ngôn ngữ (Cross-language Generation)
Từ duy nhất một file `battlefield.proto`, công cụ `protoc` tự động sinh mã nguồn cho nhiều ngôn ngữ:
- **Golang (Backend & Simulator):** Sinh ra các `struct` Go và interface gRPC giúp Backend dễ dàng cấp phát vùng nhớ và xử lý logic.
- **Dart (Flutter Client):** Sinh ra các `class` Dart (kế thừa `GeneratedMessage`) để Frontend lập tức parse binary payload từ gRPC mà không cần bước ánh xạ JSON trung gian.
=> Mọi thay đổi cấu trúc dữ liệu (như đổi tên, thêm field) đều được ép kiểu (strongly-typed) ở lúc compile, loại bỏ hoàn toàn các lỗi "sai chính tả tên trường" cực kỳ tốn thời gian debug của JSON.

### 1.2. Phân lớp Data Models
Trong `battlefield.proto`, dữ liệu được chia làm 3 phân lớp rõ rệt:
- **Event Models (`FlightEvent`, `MilitaryEvent`):** Được dùng bởi **Simulator** để nén dữ liệu nội bộ và publish qua Message Queue (NATS). Chứa các trường đặc tả vật lý như `lat, lon, speed, heading, threat_level`.
- **Normalized Model (`RadarObject`):** Dữ liệu chuẩn hóa tại Backend. Dù là máy bay dân dụng OpenSky hay Tên lửa giả lập, khi Backend nhận được đều quy về một chuẩn `RadarObject` duy nhất. Field `layer` (`CIVIL` hoặc `MILITARY`) được thêm vào để phân biệt nguồn gốc.
- **Payload Model (`RadarSnapshot`):** Đây là payload thực tế truyền qua đường truyền Internet gRPC. Thay vì gửi 1.000 requests nhỏ cho 1.000 máy bay, Backend gom toàn bộ objects vào một mảng `repeated RadarObject objects` cùng block thống kê `SnapshotStats`. Phương pháp bọc gói (Batching) này tối ưu hóa triệt để Overhead của giao thức TCP.

### 1.3. Cơ chế tương thích ngược (Backward Compatibility)
Protobuf định danh các trường bằng con số (Tag ID) thay vì chuỗi Text, ví dụ: `string callsign = 4;`. Nhờ vậy:
- Backend có thể thảnh thơi thêm trường dữ liệu mới (ví dụ: `int32 fuel_status = 13;`) mà Client cũ hoàn toàn không bị crash (Client tự động lờ đi các field không biết).
- Cho phép đội ngũ Frontend và Backend nâng cấp hệ thống độc lập theo mô hình Agile mà không bao giờ sợ làm gãy API Contract hiện tại.

---

## 2. gRPC Real-time Streaming (Radar Server)

Backend sử dụng cơ chế **Server-Streaming RPC** của gRPC để đẩy dữ liệu xuống Client.

### 2.1. In-Memory State
Hệ thống không truy vấn Database để lấy vị trí hiển thị lên Radar vì tốc độ đọc/ghi của SQL không thể đáp ứng Real-time (10 frames/s). Thay vào đó, nó duy trì trạng thái trong RAM:
```go
type RadarServer struct {
    bfpb.UnimplementedRadarServiceServer
    mu      sync.RWMutex
    objects map[string]*bfpb.RadarObject
}
```
- Khi NATS nhận event, nó gọi `UpsertObject` để ghi vào map. Thao tác này được bảo vệ bởi khóa `sync.RWMutex` để chống Data Race.

### 2.2. Tick Broadcast (Server-Streaming)
Hàm `StreamRadar` mở một luồng kết nối TCP/HTTP2 liên tục với Client:
- Sử dụng `time.NewTicker(100 * time.Millisecond)`, Backend hoạt động ở tần số **10Hz**.
- Cứ mỗi 100ms, Backend sẽ khóa Read-lock (`mu.RLock()`), gom toàn bộ đối tượng trong `objects` map, build thành `RadarSnapshot` và gọi `stream.Send(snapshot)`.
- Kiến trúc này giúp luồng dữ liệu 1 chiều (Backend -> Client) đạt độ trễ siêu thấp và cực kỳ ổn định.

---

## 3. Tracking Service & Database Layer

Mặc dù việc vẽ Radar lấy từ RAM, việc lưu trữ lịch sử để phân tích, báo cáo hoặc playback lại là nhiệm vụ của Database Layer.

### 3.1. Tracking Service (Business Logic)
Là tầng trung gian nhận dữ liệu từ NATS Handlers và gọi xuống Repository. Tầng này giúp cô lập logic nghiệp vụ khỏi các câu lệnh SQL. Nó cung cấp 3 thao tác chính:
- `SaveAircraft`: Lưu thông tin định danh máy bay.
- `UpdateTrackingCurrent`: Lưu tọa độ hiện tại.
- `SaveTrackingHistory`: Lưu lịch sử tọa độ.

### 3.2. PostgreSQL Repository (Data Persistence)
Tầng Repository (`PostgresRepository`) sử dụng thư viện `sqlx` để tương tác trực tiếp với PostgreSQL thông qua các raw SQL Query:

**Cơ chế Upsert (Cập nhật vị trí hiện tại):**
Để bảng `tracking` luôn chứa vị trí *mới nhất* của mỗi đối tượng, Postgres dùng cú pháp `ON CONFLICT DO UPDATE`:
```sql
INSERT INTO tracking (icao24, latitude, longitude, altitude, speed, heading, last_updated)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (icao24)
DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    ...
```
Cơ chế này xử lý hoàn hảo việc một máy bay bay vào vùng phủ sóng: Lần đầu tiên nó sẽ `INSERT`, các tích tắc tiếp theo nó sẽ tự động `UPDATE` mà không cần code logic kiểm tra tồn tại (IF EXISTS) ở Go.

**Cơ chế Append-only (Lịch sử bay):**
Bảng `track_history` phục vụ việc vẽ đường bay (flight path). Hàm `SaveTrackingHistory` thực hiện câu lệnh `INSERT` thuần túy. Hàng trăm/nghìn row được sinh ra mỗi giây cho phép hệ thống tua lại (replay) toàn bộ cục diện chiến trường theo bất kỳ mốc thời gian nào.
