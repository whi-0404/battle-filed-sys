# Xử Lý Dữ Liệu gRPC Phía Flutter Client

Tài liệu này mô tả chi tiết cách ứng dụng Flutter (Client) thiết lập kết nối, lắng nghe (subscribe) và chuyển đổi dòng dữ liệu gRPC khổng lồ từ Backend thành trạng thái (State) để hiển thị lên bản đồ theo thời gian thực.

---

## 1. Kiến Trúc Luồng Dữ Liệu Phía Client
Dữ liệu di chuyển trong nội bộ Flutter Client theo mô hình một chiều (Unidirectional Data Flow):
`gRPC Stub (Network)` ➔ `StreamController (Service)` ➔ `ChangeNotifier (Provider)` ➔ `Flutter UI (Widgets)`

Kiến trúc này đảm bảo UI luôn được vẽ lại (rebuild) tự động và mượt mà mỗi khi có tín hiệu mạng bay về, đồng thời tách biệt hoàn toàn Logic Mạng (Network) ra khỏi Logic Giao diện.

---

## 2. Quá Trình Kết Nối và Bắt Dữ Liệu gRPC

Toàn bộ logic mạng nằm trong lớp `RadarGrpcService` (`client/lib/services/radar_service.dart`).

### Bước 2.1: Khởi tạo Kênh Truyền (ClientChannel)
Client mở một kết nối TCP bền vững (HTTP/2) tới Backend thông qua `ClientChannel`. 
```dart
_channel = ClientChannel(
  'localhost', // Đổi thành '10.0.2.2' nếu dùng Android Emulator
  port: 50051,
  options: const ChannelOptions(
    credentials: ChannelCredentials.insecure(), // Không dùng SSL cho môi trường Dev
    connectionTimeout: Duration(seconds: 5),
  ),
);

// Khởi tạo gRPC Stub (Lớp trung gian do Protobuf tự động sinh ra)
_stub = RadarServiceClient(_channel!);
```

### Bước 2.2: Lắng nghe gRPC Server Streaming
Vì Backend cấu hình hàm `StreamRadar` dưới dạng Server Streaming (đẩy data liên tục trên 1 request duy nhất), Client chỉ cần gọi hàm này 1 lần duy nhất và đăng ký một `.listen()` để "hứng" data rơi xuống:

```dart
// Gọi RPC request lên Server
final grpcStream = _stub!.streamRadar(bf.StreamRadarRequest());

// Lắng nghe liên tục
grpcStream.listen(
  (snap) {
    // Mỗi khi Server gửi 1 RadarSnapshot (mỗi 100ms), hàm này sẽ kích hoạt
    print("Nhận được bản tin với ${snap.objects.length} máy bay!");
    
    // Đẩy data vào Stream nội bộ của App
    _controller.add(RadarSnapshotModel.fromProto(snap));
  },
  onError: (e) {
    print('Kết nối gRPC bị đứt: $e');
  },
  onDone: () {
    print('Server đã chủ động đóng kết nối gRPC');
  },
);
```

---

## 3. Chuyển Đổi Dữ Liệu (Deserialize & Mapping)

Gói dữ liệu `snap` trả về từ `grpcStream` là các Object thuần túy của Protobuf (`pb.dart`). Chúng rất thô sơ và gắn liền với thư viện gRPC. Để sử dụng an toàn trong Flutter, chúng ta cần biến đổi (Map) chúng sang các Dart Model thông thường (`client/lib/models/radar_object.dart`).

```dart
factory RadarObjectModel.fromProto(proto.RadarObject p) {
    return RadarObjectModel(
      id: p.id,
      type: p.type, // Enum từ Protobuf
      layer: p.layer,
      callsign: p.callsign,
      lat: p.lat,
      lon: p.lon,
      speed: p.speed,
      heading: p.heading,
      threatLevel: p.threatLevel,
      lastUpdated: p.lastUpdated.toDateTime(), // Chuyển từ Timestamp của Google sang DateTime Dart
    );
}
```
Lợi ích của bước này là bóc tách hoàn toàn UI ra khỏi các thư viện cấu trúc nhị phân của Google.

---

## 4. Quản Lý Trạng Thái (State Management với Provider)

Để biến hàng ngàn tọa độ vô tri trên RAM thành các điểm nhấp nháy trên bản đồ, Client sử dụng thư viện `provider`. 
Lớp `RadarProvider` (`client/lib/providers/radar_provider.dart`) đóng vai trò là "Nhạc trưởng". Nó lắng nghe Stream nội bộ từ `RadarGrpcService` và phát lệnh Render lại màn hình.

```dart
// Khởi động kết nối mạng
await _service.connect();

// Lắng nghe dữ liệu đã qua xử lý (Dart Models)
_service.stream.listen((snap) {
    // Cập nhật State nội bộ
    _objects = snap.objects;
    _stats = snap.stats;
    
    // Gầm lên báo hiệu cho tất cả Widget trên màn hình biết "Có Data mới rồi, vẽ lại đi!"
    notifyListeners(); 
});
```

Ở file UI (`map_page.dart`), Widget bản đồ `FlutterMap` và các Widget thống kê chỉ việc "cắm rễ" (watch) vào `RadarProvider`. Mỗi khi `notifyListeners()` được gọi, chúng sẽ tự động bốc lấy tọa độ mới nhất và thay đổi vị trí Marker trên bản đồ trong nháy mắt.

---

## 5. Tổng Kết Chu Trình 100ms
Quy trình từ lúc bắt gRPC đến lúc hiện lên UI diễn ra theo nhịp độ siêu tốc (10 lần 1 giây):
1. **0ms:** Backend gửi gói tin `RadarSnapshot` qua HTTP/2.
2. **~1ms:** Mạng LAN truyền tin đến Dart HTTP/2 Client.
3. **~2ms:** Protobuf giải nén (Deserialize) mảng Byte nhị phân ra thành Object. `grpcStream.listen` được kích hoạt.
4. **~3ms:** Data được convert qua `RadarSnapshotModel` và tuồn vào ống `StreamController`.
5. **~4ms:** `RadarProvider` bắt được data, cập nhật State, gọi `notifyListeners()`.
6. **~16ms (Chu kỳ 60fps):** Render Engine của Flutter (Skia/Impeller) vẽ lại 5000+ Icon máy bay theo tọa độ mới trên màn hình.

Tất cả các bước diễn ra nhẹ nhàng, mượt mà và không hề gây khựng khung hình (Jank) nhờ sự tối ưu tuyệt vời của gRPC và khả năng vẽ siêu tốc của Flutter.
