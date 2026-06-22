# Hướng Dẫn Vận Hành Hệ Thống Battlefield Radar (Từ A-Z)

Tài liệu này hướng dẫn bạn cách khởi động toàn bộ hệ thống từ con số 0, bao gồm việc nạp dữ liệu lịch sử (Ingest Data), khởi chạy Backend, Simulator và giao diện Flutter Client.

---

## 1. Yêu Cầu Hệ Thống (Prerequisites)
- **Docker & Docker Compose:** Dành cho việc chạy PostgreSQL và NATS Server.
- **Go (Golang):** Phiên bản >= 1.20 để chạy Backend và Simulator.
- **Flutter SDK:** Cài đặt sẵn để chạy giao diện Client. (Khuyến nghị bật chế độ Desktop: `flutter config --enable-windows-desktop`).

---

## 2. Bước 1: Khởi Động Hạ Tầng (Infrastructure)

Mở Terminal (Command Prompt / PowerShell) và đi tới thư mục `backend`:
```bash
cd backend
docker-compose up -d
```
Lệnh này sẽ tải và chạy 2 container ở chế độ ngầm (background):
- **PostgreSQL:** Chạy trên port `5432` (Username: `admin`, Password: `postgres`, DB: `battlefield`).
- **NATS Message Broker:** Chạy trên port `4222`.

---

## 3. Bước 2: Nạp Dữ Liệu Lịch Sử (Data Ingestion)

Để Simulator có dữ liệu bay để mô phỏng, chúng ta cần nạp các file CSV từ OpenSky vào Database.

1. Đảm bảo bạn đã có các file CSV dữ liệu bay (Ví dụ: `states_2022-06-20-00.csv`) nằm trong thư mục `backend/data-crawl/`.
2. Mở Terminal tại thư mục `backend` và chạy tool Ingester:
   ```bash
   cd backend
   go run cmd/ingester/main.go
   ```
3. Chờ đợi phép màu xảy ra. Nhờ được tối ưu bằng lệnh `COPY`, hệ thống sẽ "nhồi" hơn **3.7 triệu bản ghi** vào PostgreSQL chỉ trong vỏn vẹn **1 đến 2 phút**. Khi terminal báo `Ingestion completed 100%`, bạn đã sẵn sàng!

---

## 4. Bước 3: Khởi Chạy Backend Server

Mở một Terminal **MỚI**, giữ nguyên terminal cũ nếu muốn.
```bash
cd backend
go run cmd/main.go
```
Backend sẽ làm 2 việc:
- Kết nối tới NATS để hứng dữ liệu.
- Mở cổng gRPC `50051`. 
Khi bạn thấy dòng log `[main] gRPC server listening on :50051`, Backend đã vào tư thế sẵn sàng phục vụ.

---

## 5. Bước 4: Khởi Chạy Simulator (Máy Phát Dữ Luệu)

Mở một Terminal **MỚI**.
Simulator sẽ kết nối tới DB, đọc dữ liệu `track_history`, nội suy tọa độ và bắn lên NATS.

```bash
cd simulator

# Trên Windows PowerShell:
$env:DATABASE_URL="postgres://admin:postgres@localhost:5432/battlefield?sslmode=disable"
go run cmd/main.go

# Hoặc trên Git Bash / Linux / macOS:
DATABASE_URL="postgres://admin:postgres@localhost:5432/battlefield?sslmode=disable" go run cmd/main.go
```
Khi Simulator báo `Started replay from...`, nghĩa là dữ liệu đã bắt đầu tuôn trào trên hệ thống mạng NATS!

---

## 6. Bước 5: Khởi Chạy Giao Diện Flutter (Client)

Mở một Terminal **MỚI** cuối cùng.
```bash
cd client
flutter pub get
```

Chạy ứng dụng dưới dạng Desktop App (Tối ưu và mượt nhất cho gRPC):
```bash
flutter run -d windows
```

### ⚠️ Lưu ý Dành Cho Máy Ảo Android (Android Emulator)
Nếu bạn không chạy Desktop mà chạy trên điện thoại ảo Android, app sẽ bị lỗi không kết nối được `localhost`.
**Cách sửa:** Mở file `client/lib/services/radar_service.dart`, tìm dòng 9:
```dart
static const String _host = 'localhost'; 
```
Sửa thành:
```dart
static const String _host = '10.0.2.2'; 
```
Sau đó lưu lại và nhấn `R` (Hot Restart) trên terminal.

---

## 🎉 Tận Hưởng Kết Quả
Ngay khi ứng dụng Flutter hiện lên, bản đồ sẽ tự động chuyển về chế độ Dark Mode, và bạn sẽ thấy hàng ngàn chuyến bay dân dụng cùng với các UAV, Tên lửa nhấp nháy và di chuyển mượt mà liên tục mỗi giây!
