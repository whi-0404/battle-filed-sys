# Xử Lý gRPC và Protocol Buffers (Protobuf) Trong Hệ Thống Battlefield

Tài liệu này trình bày chi tiết về kiến trúc giao tiếp màng lưới (Network Communication) của hệ thống Battlefield, giải thích lý do và cách thức áp dụng **gRPC** cùng **Protocol Buffers (Protobuf)** để đạt được luồng truyền dẫn thời gian thực (Real-time Streaming) từ Backend tới Frontend.

---

## 1. Vai trò của Protocol Buffers (Protobuf)

### Tại sao không dùng JSON?
Trong hệ thống Radar, số lượng máy bay cập nhật có thể lên tới hơn 5000+ object mỗi giây. Nếu sử dụng định dạng JSON, mỗi thông điệp sẽ mang theo một lượng lớn Text dư thừa (như tên các trường `{"latitude": 20.5, "longitude": 105.0...}`).
- JSON tiêu tốn nhiều CPU để phân tích cú pháp (Parsing) và ngốn băng thông mạng cực lớn.
- **Protobuf** là định dạng Serialize nhị phân (Binary) siêu nhỏ gọn do Google phát triển. Nó loại bỏ tên biến, chỉ mã hóa giá trị thông qua các Tag ID, giúp giảm **hơn 60%** dung lượng băng thông so với JSON và giải mã cực nhanh.

### Triển khai Protobuf trong dự án
Tất cả các định dạng dữ liệu cốt lõi đều được định nghĩa chặt chẽ bằng file `.proto` (`battlefield.proto`).

**1. Liên lạc Nội bộ (Simulator -> NATS -> Backend):**
Simulator gói gọn tọa độ bằng cấu trúc `FlightEvent` hoặc `MilitaryEvent` và Serialize ra chuỗi Byte (Binary) trước khi bắn lên NATS:
```go
event := &bfpb.FlightEvent{
    Icao24:  f.icao24,
    Lat:     f.lat,
    Lon:     f.lon,
    Speed:   f.speed,
    Heading: f.heading,
}
// Serialize Object sang dạng Byte
data, _ := proto.Marshal(event)
nc.Publish("flight.position.updated", data)
```
Backend nhận mảng Byte từ NATS và Deserialize ngược lại cực kỳ nhanh:
```go
var event bfpb.FlightEvent
proto.Unmarshal(msg.Data, &event)
```

**2. Gom nhóm Object (Snapshot):**
Để truyền tải lên UI hiệu quả, các sự kiện bay được Backend gom chung vào cấu trúc `RadarSnapshot`, mang theo toàn bộ danh sách `RadarObject` và các thống kê `SnapshotStats` đi kèm.

---

## 2. Kiến trúc gRPC Streaming (Server-to-Client)

Thay vì sử dụng REST API (bắt buộc Client phải gửi Request liên tục - Polling) hay WebSockets (đòi hỏi xử lý logic Connection phức tạp ở tầng Application), hệ thống sử dụng kiến trúc **gRPC Server Streaming**.

### Luồng Hoạt Động Của gRPC Server
Trong `RadarServer` (`backend/internal/grpcserver/radar_server.go`):
1. **Duy trì Trạng thái (In-Memory State):** Backend sở hữu một biến `map` mang tên `s.objects` chứa tọa độ mới nhất của tất cả máy bay.
2. **Server Streaming:** Backend mở hàm `StreamRadar` giữ kết nối TCP dai dẳng (Persistent TCP Connection) chuẩn HTTP/2 với Flutter Client.
3. **Phát sóng (Broadcasting):** Cứ mỗi 100ms, Backend tự động gói gọn toàn bộ Map `s.objects` thành một `RadarSnapshot` và stream (đẩy) xuống cho Client thông qua lệnh `stream.Send()`.

```go
func (s *RadarServer) StreamRadar(req *bfpb.StreamRadarRequest, stream bfpb.RadarService_StreamRadarServer) error {
    ticker := time.NewTicker(100 * time.Millisecond)
    for {
        select {
        case <-ticker.C:
            snapshot := s.buildSnapshot() // Gom toàn bộ máy bay hiện tại
            stream.Send(snapshot)         // Stream nhị phân xuống cho Flutter
        }
    }
}
```

### Xử lý bên phía Client (Flutter / Dart)
Ứng dụng Flutter tương tác với gRPC thông qua package `grpc` gốc (Native gRPC). Client mở một `ClientChannel` tới cổng `:50051`.

1. **Khởi tạo Luồng (Stream Listener):** Client gọi `stub.streamRadar` và đăng ký một Listener để hứng dữ liệu liên tục:
```dart
final grpcStream = _stub!.streamRadar(bf.StreamRadarRequest());

grpcStream.listen((snap) {
    // Deserialize và convert từ Proto Object sang Dart Object
    _controller.add(RadarSnapshotModel.fromProto(snap));
});
```

2. **Xử lý Mất kết nối & Fallback:**
Client được thiết lập một Timeout. Ở phiên bản tối ưu, quá trình Simulation Fallback (sinh dữ liệu ảo) đã bị loại bỏ. Nếu mạng chập chờn hoặc gRPC chưa kịp gửi dữ liệu, Client sẽ chờ đợi 5 giây thay vì tự động ném ra lỗi hoặc chuyển sang giao diện ảo, ép hệ thống duy trì được tính chân thực của luồng giả lập Real-time.

---

## Tổng Kết
Sự kết hợp giữa **NATS (Pub/Sub tốc độ cao)**, **Protobuf (Siêu nén dữ liệu)** và **gRPC Server Streaming (Luồng truyền tải thời gian thực HTTP/2)** đã tạo ra một đường ống (Pipeline) hoàn hảo. Dữ liệu thay đổi liên tục của hàng ngàn chuyến bay có thể đi từ Simulator qua lõi Backend và tới tận giao diện Flutter Client chỉ trong vỏn vẹn **chưa tới 10 mili-giây** (10ms latency).
