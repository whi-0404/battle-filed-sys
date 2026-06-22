# Phân Tích Chi Tiết Cấu Trúc Truy Vấn Cơ Sở Dữ Liệu (PostgreSQL)

Tài liệu này phân tích chi tiết các kỹ thuật truy vấn SQL đang được hệ thống Battlefield vận hành nhằm tối ưu hóa việc đọc ghi ở tốc độ cao và bảo đảm tính toàn vẹn dữ liệu.

---

## 1. Kỹ Thuật UPSERT Trong Môi Trường Real-time

Khái niệm **UPSERT** (Update or Insert) đặc biệt quan trọng trong các hệ thống tracking đối tượng. Khi nhận được một thông điệp từ NATS, hệ thống không biết chắc máy bay này là mới xuất hiện trên radar hay đã tồn tại từ trước.

Trong thư mục `backend/internal/tracking/repository/postgres_repository.go`, chúng ta áp dụng mệnh đề `ON CONFLICT` của PostgreSQL:

### Truy vấn lưu thông tin máy bay (SaveAircraft)
```sql
INSERT INTO aircraft (
    icao24, callsign, type, status, created_at, updated_at
)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (icao24)
DO UPDATE SET
    callsign = EXCLUDED.callsign,
    type = EXCLUDED.type,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at
```
- **Ý nghĩa:** Cố gắng `INSERT` một dòng máy bay mới dựa trên khóa chính (`icao24`). Nếu PostgreSQL phát hiện `icao24` này đã có trong bảng (`ON CONFLICT`), nó sẽ lập tức chuyển sang lệnh `UPDATE` để ghi đè các cột bằng giá trị mới nhất (`EXCLUDED.tên_cột`).
- **Ưu điểm:** Giảm một nửa số lượng truy vấn (thay vì phải `SELECT` kiểm tra tồn tại rồi mới `INSERT` hoặc `UPDATE`), chống Race Condition.

### Truy vấn cập nhật tọa độ hiện tại (UpdateCurrentTrack)
Hoạt động với cơ chế UPSERT tương tự bảng `aircraft`, bảng `tracking` sẽ liên tục ghi đè tọa độ `latitude`, `longitude`, `speed` và `heading` của cùng một `icao24`. Bảng này luôn chỉ giữ 1 bản ghi duy nhất cho 1 máy bay (thể hiện vị trí mới nhất của nó).

---

## 2. Truy Vấn Nội Suy (Interpolation Query) Của Simulator

Simulator (`HistoricalPoller`) có nhiệm vụ chớp lấy tọa độ chuẩn từ Database mỗi 10 giây để vá lỗi sai lệch trong quá trình nội suy Dead Reckoning.

### Kỹ thuật Query Windowing (Truy vấn theo khung thời gian)
Thay vì quét (scan) toàn bộ database, `HistoricalPoller` chỉ "cắn" một khoảng thời gian 1 giây thông qua tham số mốc (Windowing):

```sql
SELECT h.icao24, a.callsign, h.latitude, h.longitude, h.altitude, h.heading, h.speed
FROM track_history h
JOIN aircraft a ON h.icao24 = a.icao24
WHERE h.snapshot_at >= $1 AND h.snapshot_at < $2
```
- `$1` và `$2` là mốc thời gian chênh lệch nhau 1 giây (Ví dụ: từ `00:00:10` đến `00:00:11`).
- `JOIN aircraft a ON h.icao24 = a.icao24`: Phép kết nối chéo giữa bảng `track_history` và bảng danh mục `aircraft` để lấy ra tên chuyến bay (`callsign`) vì trong `track_history` chỉ lưu mã ICAO24 để tiết kiệm ổ cứng.

---

## 3. Truy Vấn Bulk Copy (Ingester)

Đây là thao tác SQL "nặng đô" nhất của dự án, nằm trong `cmd/ingester/main.go`. Khi xử lý file CSV khổng lồ chứa 3.7 triệu records:

```go
stmt, _ := txn.Prepare(pq.CopyIn("track_history", "icao24", "latitude", "longitude", "altitude", "heading", "speed", "snapshot_at"))
```
- Hàm `pq.CopyIn` phía dưới dùng câu lệnh `COPY track_history (cột_1, cột_2, ...) FROM STDIN`.
- **Ý nghĩa:** Đây không phải là SQL Query thông thường. Đây là cơ chế Streaming nhị phân cấp thấp của PostgreSQL. Dữ liệu từ file CSV sẽ được bơm dưới dạng dòng suối byte thẳng vào bộ lưu trữ của Database mà không cần chạy qua bộ phận phân tích ngữ pháp SQL (SQL Parser).
- Đây là lý do chúng ta Ingest vài triệu bản ghi chỉ mất có 1 phút!

---

## 4. An Toàn Đa Luồng (Concurrency Safety)

Vì `db *sqlx.DB` trong hệ sinh thái Go là một Connection Pool (Hồ chứa kết nối) an toàn đa luồng (Thread-safe), chúng ta sử dụng `db.ExecContext(ctx, ...)` và `db.QueryContext(ctx, ...)`.
- Mọi hàm truy vấn đều mang theo `context.Context` (ctx) để có thể chủ động hủy (Cancel) lệnh truy vấn hoặc đặt Timeout (Hết giờ) nếu Database bị treo cứng, ngăn chặn hiện tượng rò rỉ bộ nhớ phía Backend.
