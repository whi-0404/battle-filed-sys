# Hướng Dẫn Nhập Môn Hệ Thống Flutter Client (Dành Cho Newbie)

Chào mừng bạn đến với dự án **Battlefield Radar Client**! Tài liệu này được biên soạn đặc biệt dành cho các Developer chưa từng tiếp xúc với Flutter trước đây. Mục tiêu là giúp bạn nắm bắt nhanh chóng cấu trúc thư mục, triết lý thiết kế và luồng hoạt động của hệ thống Frontend này để có thể bắt tay vào code ngay lập tức.

---

## 1. Flutter Là Gì? (Khái Niệm Cốt Lõi)

Flutter là một framework do Google phát triển, cho phép bạn viết code 1 lần bằng ngôn ngữ **Dart** và biên dịch chạy trên đa nền tảng (iOS, Android, Web, Windows, macOS, Linux).

Trong Flutter, mọi thứ bạn nhìn thấy trên màn hình đều là **Widget**.
- Cửa sổ ứng dụng là một Widget.
- Một nút bấm (Button) là một Widget.
- Một đoạn text hay một khoảng trống (Padding) cũng là Widget.

Flutter sử dụng phong cách **Giao diện Khai báo (Declarative UI)**. Nghĩa là bạn không cần phải viết code hướng dẫn UI "Cách thay đổi" (Ví dụ: `button.setText("abc")`). Thay vào đó, bạn chỉ cần thay đổi "Trạng thái" (State), và Flutter sẽ tự động gọi lệnh `build()` để vẽ lại giao diện khớp với State mới nhất.

---

## 2. Cấu Trúc Thư Mục Của Dự Án

Mã nguồn chính của ứng dụng nằm hoàn toàn trong thư mục `client/lib/`. Cấu trúc được chia theo chuẩn **Feature-based Architecture** (Kiến trúc theo chức năng) cực kỳ gọn gàng:

```text
client/lib/
 ├── main.dart                  # Cánh cửa bước vào ứng dụng (Entry point).
 ├── models/                    # Các cấu trúc dữ liệu thuần túy (Dart class).
 │    └── radar_object.dart     # Nơi định nghĩa cấu trúc của 1 Máy bay/UAV.
 ├── proto/                     # Code tự động sinh ra từ file .proto (KHÔNG SỬA thủ công).
 ├── providers/                 # Quản lý Trạng thái (State Management).
 │    └── radar_provider.dart   # Nơi chứa và thông báo Data cho toàn bộ giao diện.
 ├── services/                  # Các lớp giao tiếp với thế giới bên ngoài (Network/API).
 │    └── radar_service.dart    # Chịu trách nhiệm kết nối gRPC tới Backend.
 ├── theme/                     # Chứa các file quy định màu sắc, font chữ chung.
 │    └── app_colors.dart
 └── features/                  # Chứa các giao diện chia theo từng màn hình.
      └── map/
           ├── map_page.dart    # Màn hình chính chứa Bản đồ Radar.
           └── widgets/         # Chứa các mảnh giao diện nhỏ lẻ cắt ra từ màn hình chính.
```

---

## 3. Luồng Hoạt Động (Life-cycle)

Hãy tưởng tượng bạn vừa click đúp để mở ứng dụng. Chuyện gì sẽ xảy ra?

**1. `main.dart` - Vạch xuất phát:**
- Ứng dụng chạy hàm `main()`.
- Lệnh `runApp(MyApp())` được gọi để khởi động khung UI.
- Ngay tại đây, nó bọc toàn bộ ứng dụng bằng một `MultiProvider`. Hãy coi Provider như một "Cái Loa Phường" phát sóng dữ liệu từ trên trời rơi xuống cho bất cứ màn hình nào cần nghe.

**2. `radar_service.dart` - Người Lấy Tin (The Messenger):**
- Ngay khi App chạy, `RadarGrpcService` sẽ lặng lẽ mở kết nối mạng (gRPC) vào cổng `localhost:50051` của Backend.
- Cứ 100 mili-giây, nó nhận được 1 cục dữ liệu (Chứa 5000+ máy bay). Nó đẩy cục dữ liệu này vào ống nước `Stream`.

**3. `radar_provider.dart` - Nhạc Trưởng (The Conductor):**
- Provider "đứng đợi" ở cuối ống nước. Khi có dữ liệu mới tuồn ra, nó lưu danh sách 5000 máy bay vào bộ nhớ.
- Quan trọng nhất: Nó hét lên lệnh `notifyListeners()` (Báo động: Dữ liệu đã thay đổi!).

**4. `map_page.dart` - Họa sĩ (The Painter):**
- Màn hình bản đồ (`FlutterMap`) đã đăng ký "nghe" cái Loa Phường từ trước qua lệnh `context.watch<RadarProvider>()`.
- Khi nghe tiếng hét `notifyListeners()`, màn hình tự động bừng tỉnh, chạy lại hàm `build()`.
- Vòng lặp `for` chạy qua 5000 máy bay, ghim 5000 cái Icon nhấp nháy (`Marker`) lên bản đồ. Tada! Bạn thấy máy bay di chuyển!

---

## 4. Thư Viện Bản Đồ (flutter_map)
Chúng ta đang sử dụng package `flutter_map` (giống hệ sinh thái Leaflet của JavaScript).

- Bản đồ là tập hợp của nhiều lớp (Layers) xếp chồng lên nhau như bánh Hamburger:
  1. **TileLayer:** Lớp dưới cùng. Trải các bức ảnh bản đồ màu tối (Dark Mode) tải từ máy chủ `cartocdn.com` lên nền màn hình.
  2. **MarkerLayer:** Lớp bên trên. Đặt các Icon (máy bay, tên lửa) lên tọa độ kinh độ/vĩ độ (`lat/lon`) tương ứng.

Nếu bạn muốn thay đổi màu sắc, độ to nhỏ của máy bay, bạn hãy tìm file `client/lib/features/map/widgets/radar_marker.dart`. 

---

## 5. Bắt Đầu Viết Code Như Thế Nào?

1. Đảm bảo bạn đã cài đặt **Flutter SDK** và VS Code (cài thêm Extension Flutter).
2. Mở terminal, đi tới thư mục `client`. Chạy lệnh tải thư viện:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng dưới dạng Desktop App trên Windows:
   ```bash
   flutter run -d windows
   ```
4. Thử sức: Bạn hãy vào file `map_page.dart`, tìm đoạn vẽ viền bao quanh (Border) của bản đồ và thử đổi màu của nó từ Xanh lá (Green) sang Đỏ (Red). Lưu file lại, nhấn `r` trên Terminal để **Hot Reload** (Cập nhật giao diện trong chưa tới 1 giây mà không cần tắt App).

Chúc bạn có những trải nghiệm code tuyệt vời và nhanh chóng làm chủ Flutter!
