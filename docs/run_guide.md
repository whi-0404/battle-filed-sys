# Hướng dẫn chạy Full Project Battlefield Radar

Tài liệu này hướng dẫn chi tiết cách khởi chạy toàn bộ hệ thống từ Database, Backend, Simulator đến Client (Flutter).

## 1. Yêu cầu hệ thống (Prerequisites)
- **Docker & Docker Compose**: Để chạy PostgreSQL và NATS.
- **Go (Golang)**: Phiên bản 1.20 trở lên để chạy Backend và Simulator.
- **Flutter SDK**: Phiên bản 3.0+ để chạy Client.
- **golang-migrate**: Dùng để chạy file migration database (Tuỳ chọn nếu bạn chạy bằng script trực tiếp trong DB).

## 2. Khởi chạy Hạ tầng (Infrastructure)
Hệ thống yêu cầu NATS (Message Broker) và PostgreSQL (Database).
1. Mở terminal tại thư mục `backend`.
2. Tạo file `.env` dựa trên `.env.example`:
   ```bash
   cp .env.example .env
   ```
   *Cập nhật thông tin trong file `.env` nếu cần thiết (ví dụ: POSTGRES_USER, POSTGRES_PASSWORD, DB_NAME).*
3. Chạy các container bằng Docker Compose:
   ```bash
   docker-compose up -d
   ```
   *NATS sẽ chạy ở port 4222, Postgres sẽ chạy ở port 5432.*

4. **Chạy Database Migration:**
   Sử dụng công cụ `golang-migrate` để nạp các file schema trong thư mục `backend/migrations/` vào Database:
   ```bash
   migrate -path migrations -database "postgres://<user>:<password>@localhost:5432/<dbname>?sslmode=disable" up
   ```

## 3. Khởi chạy Backend (Core Server)
Backend sẽ hứng dữ liệu từ NATS, lưu vào Postgres và mở gRPC Server tại port 50051.
1. Mở terminal tại thư mục `backend`.
2. Tải các dependencies (nếu chưa có):
   ```bash
   go mod tidy
   ```
3. Chạy Backend:
   ```bash
   go run cmd/main.go
   ```
   *Console sẽ in ra log "Connected to NATS", "Database connected" và "gRPC server listening on :50051".*

## 4. Khởi chạy Simulator (Nguồn phát dữ liệu)
Simulator lấy dữ liệu OpenSky và tạo giả lập quân sự, sau đó đẩy lên NATS.
1. Mở một terminal mới tại thư mục `simulator`.
2. (Tùy chọn) Cấu hình `.env` cho OpenSky API auth nếu cần để tránh bị giới hạn lượt gọi (Rate-limit).
3. Chạy Simulator:
   ```bash
   go run cmd/main.go
   ```
   *Console sẽ in ra log "Published: ICAO..." và các Engine quân sự đã khởi chạy.*

## 5. Khởi chạy Client (Flutter Radar)
Client dùng gRPC để nhận dữ liệu Real-time từ Backend và render lên bản đồ.
1. Mở một terminal mới tại thư mục `client`.
2. Tải các package Flutter:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng trên nền tảng mong muốn (ưu tiên Desktop/Windows để gRPC hoạt động mượt mà với `localhost`):
   ```bash
   flutter run -d windows
   ```
   *Lưu ý: Nếu bạn chạy trên trình duyệt (Web), gRPC nguyên bản sẽ không hỗ trợ và Client sẽ tự động rơi vào chế độ Mock Simulation.*
4. Radar sẽ hiển thị bản đồ Việt Nam, các đường ScanLine, GridLayer và các máy bay (Civil/Military) di chuyển theo thời gian thực (10 khung hình / 1 giây).

---
**Troubleshooting (Sửa lỗi thường gặp):**
- **Trắng màn hình hoặc Lỗi tải Map (404):** Hãy chắc chắn bạn có kết nối mạng Internet để thư viện `flutter_map` tải bản đồ (CartoDB Dark).
- **Client không thấy object thật (Tự chạy fallback object):** Có thể Client không gọi được `localhost:50051` (Do chạy trên Emulator Android/iOS). Hãy chạy app bằng `windows` hoặc đổi `localhost` trong mã nguồn Flutter thành IP LAN của Backend.
- **Xung đột Port (Port conflict):** Đảm bảo các port `5432` (Postgres), `4222` (NATS), và `50051` (gRPC) trên máy bạn không bị ứng dụng khác chiếm dụng trước khi bật.
