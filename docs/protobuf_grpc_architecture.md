# Chuyên đề: Kiến trúc Protobuf và gRPC trong Battlefield Radar

Việc giám sát và vẽ hàng trăm đến hàng nghìn mục tiêu (máy bay, tên lửa, UAV) di chuyển liên tục trên bản đồ yêu cầu một hệ thống truyền tải dữ liệu có độ trễ cực thấp, băng thông nhỏ và khả năng mở rộng tốt. 

Trong hệ thống Battlefield Radar, sự kết hợp giữa **Protobuf (Protocol Buffers)** và **gRPC (gRPC Remote Procedure Calls)** là giải pháp then chốt để đạt được những yêu cầu này, vượt trội hoàn toàn so với mô hình REST API + JSON truyền thống.

---

## 1. Phân tích thiết kế Protobuf

File `battlefield.proto` đóng vai trò là hợp đồng dữ liệu (Data Contract) duy nhất giữa toàn bộ các service (Backend, Simulator) và Client (Flutter). 

### 1.1. Tại sao lại là Protobuf?
- **Binary Format:** Dữ liệu được nén dưới dạng nhị phân, nhỏ hơn rất nhiều so với text-based như JSON hay XML.
- **Tốc độ:** Parsing JSON tốn chi phí CPU để xử lý string, mảng và object. Protobuf parse/serialize siêu tốc nhờ cơ chế cấp phát trực tiếp bộ nhớ theo schema đã định trước.
- **Backward Compatibility:** Các field được đánh số (Tag ID) giúp các bản cập nhật API diễn ra suôn sẻ. Nếu Backend trả thêm trường mới, Client cũ sẽ lờ đi mà không bị ném exception.

### 1.2. Mổ xẻ `battlefield.proto`
Dưới đây là thiết kế payload được tối ưu cho bài toán Stream:

```protobuf
message RadarSnapshot {
  google.protobuf.Timestamp snapshot_at = 1;
  repeated RadarObject objects = 2; // Mảng động chứa các đối tượng
  SnapshotStats stats = 3;
}

message RadarObject {
  string id = 1;
  ObjectType type = 2;
  Layer layer = 3;
  double lat = 4;
  double lon = 5;
  double heading = 6;
  ...
}
```
**Phân tích kỹ thuật tối ưu:**
- **Sử dụng `repeated`:** Giao thức mạng luôn có Overhead (Header của TCP, IP). Việc gọi 1.000 request gRPC để lấy vị trí của 1.000 máy bay sẽ làm nghẽn cổ chai hệ thống. Thiết kế `repeated RadarObject` cho phép Backend nhồi toàn bộ bản đồ vào 1 gói tin (Batching) duy nhất mỗi khung hình, giảm thiểu Overhead.
- **Sử dụng Enum (`ObjectType`, `Layer`):** Tiết kiệm dung lượng mạng thay vì phải truyền các string như `"CIVIL"` hay `"MILITARY"`. Khi Serialize, Enum chỉ tốn khoảng 1-2 bytes (dưới dạng varint).

---

## 2. Kiến trúc gRPC Real-time Streaming

Hệ thống sử dụng mô hình **Server-side Streaming RPC**.
Khác với Unary RPC (gọi 1 lần, trả lời 1 lần giống REST), Server-streaming giữ một kết nối Persistent TCP/HTTP2 mở liên tục. Client gọi API 1 lần duy nhất, sau đó Server sẽ đẩy (Push) dữ liệu xuống liên tục.

### 2.1. Triển khai tại Backend (Golang)
Hàm `StreamRadar` trên Backend được thiết kế như một vòng lặp sự kiện (Event Loop) hoạt động ở tần số 10Hz.

```go
func (s *RadarServer) StreamRadar(req *bfpb.StreamRadarRequest, stream bfpb.RadarService_StreamRadarServer) error {
	ticker := time.NewTicker(100 * time.Millisecond) // Broadcast 10 frames/giây
	defer ticker.Stop()

	for {
		select {
		case <-stream.Context().Done():
			return nil // Client ngắt kết nối
		case <-ticker.C:
			snapshot := s.buildSnapshot()
			stream.Send(snapshot) // Đẩy qua gRPC HTTP/2 stream
		}
	}
}
```
**Tối ưu Hàng rào Memory (Memory Barrier):**
- Hàm `buildSnapshot()` thực hiện đọc (Read) trạng thái hiện tại của toàn bộ Radar Objects. Do có hàng trăm Simulator/NATS Events đang ghi (Write) liên tục vào `s.objects`, hàm này phải sử dụng `sync.RWMutex` (Cụ thể là `s.mu.RLock()`).
- Bằng cách dùng **Khóa Đọc-Ghi (RWMutex)** thay vì Mutex thông thường, Backend cho phép nhiều luồng cùng đọc dữ liệu, giúp server có thể phục vụ cùng lúc hàng nghìn Client (mỗi Client là một stream đang đọc từ map).

### 2.2. Triển khai tại Frontend (Flutter/Dart)
Bên phía Client, thư viện gRPC tự động mở kết nối HTTP/2 và chuyển hóa byte-stream thành các đối tượng Dart thông qua cơ chế Reactive Streams của Dart.

```dart
final grpcStream = _stub.streamRadar(bf.StreamRadarRequest());

grpcStream.listen(
  (snap) {
     // Hàm này được tự động trigger mỗi 100ms khi Server gọi stream.Send()
     _objects = snap.objects;
     notifyListeners(); // Báo Flutter vẽ lại bản đồ
  },
  onError: (e) { ... }
);
```

**Tại sao Dart gRPC Stream lại mượt mà?**
- Dart xử lý theo cơ chế **Event-loop Single-thread** (tương tự NodeJS). Việc `listen` trên Stream không làm đóng băng (block) UI thread.
- Khi có byte data đổ về, gRPC interceptor sẽ cắt các khung hình theo chuẩn HTTP/2 Data Frame, giải mã Protobuf và ném ra đối tượng `snap`. Tốc độ này diễn ra dưới 1ms cho hàng nghìn object, giữ cho Flutter App duy trì được 60-120 FPS khi render bản đồ.

---

## 3. Tổng kết Lợi ích

1. **Băng thông siêu nhỏ:** Kích thước payload chỉ bằng 1/10 so với JSON Array. Rất hữu ích cho thiết bị Mobile dùng 3G/4G/5G.
2. **Khả năng thời gian thực (Real-time):** Việc đẩy data thay vì Polling giúp loại bỏ hoàn toàn độ trễ khứ hồi (Round-Trip Time).
3. **An toàn kiểu dữ liệu (Type-safety):** Trình biên dịch (Compiler) đảm bảo Golang và Dart giao tiếp chuẩn 100% về kiểu dữ liệu. Sẽ không bao giờ có lỗi runtime như kiểu "Không parse được null thành double" vốn rất hay xảy ra trong JSON.
