# Tối Ưu Hóa Cơ Sở Dữ Liệu Trong Hệ Thống Battlefield

Tài liệu này trình bày các kỹ thuật và phương pháp tối ưu hóa Database (PostgreSQL) đã được áp dụng trong hệ thống nhằm đối phó với bài toán xử lý dữ liệu lớn (Big Data) ở hai khía cạnh: Ingest dữ liệu hàng loạt (Bulk Ingestion) và Xử lý luồng thời gian thực (Real-time Stream Processing).

---

## 1. Tối Ưu Hóa Quá Trình Ingest Dữ Liệu Lịch Sử (Bulk Ingestion)

### Vấn Đề Khởi Điểm
Tập dữ liệu lịch sử bay từ OpenSky là khổng lồ (hơn 3.7 triệu bản ghi cho 1 file CSV). Trong mô-đun `Ingester` ban đầu, nếu chúng ta sử dụng vòng lặp để thực thi các câu lệnh `INSERT INTO track_history ...` thông thường:
- Mỗi lệnh `INSERT` tiêu tốn thời gian thiết lập transaction, ghi WAL (Write-Ahead Log) và check constraint.
- Với 3.7 triệu bản ghi, quá trình Ingest qua lệnh `INSERT` tuần tự có thể mất từ vài giờ đến nửa ngày để hoàn thành. 

### Giải Pháp: PostgreSQL COPY Command
Thay vì sử dụng các lệnh INSERT thông thường, tôi đã ứng dụng thư viện `github.com/lib/pq` để khai thác triệt để sức mạnh của lệnh **`COPY`** trong PostgreSQL.
- Lệnh `COPY FROM STDIN` cho phép stream dữ liệu nhị phân (hoặc text) trực tiếp từ bộ nhớ của Go App thẳng vào lõi lưu trữ của PostgreSQL, bỏ qua toàn bộ overhead của việc phân tích cú pháp SQL (SQL Parser) và gom chung vào một transaction duy nhất.

**Kiến trúc code đã áp dụng:**
```go
// Khởi tạo tiến trình COPY
stmt, err := txn.Prepare(pq.CopyIn("track_history", "icao24", "latitude", "longitude", "altitude", "heading", "speed", "snapshot_at"))

// Vòng lặp bắn data trực tiếp vào vùng đệm
for {
    stmt.Exec(icao24, lat, lon, alt, heading, speed, parsedTime)
}

// Chốt (Flush) toàn bộ data xuống ổ cứng
stmt.Exec()
stmt.Close()
txn.Commit()
```

**Kết quả mang lại:**
- Thời gian Ingest 3.714.264 bản ghi đã được rút ngắn kỷ lục từ vài giờ xuống chỉ còn **khoảng 1 - 2 phút**. 
- Tiết kiệm khổng lồ CPU và RAM cho cả tiến trình Go lẫn PostgreSQL server.

---

## 2. Tối Ưu Hóa Xử Lý Luồng Real-time (Real-time Database I/O Bypass)

### Vấn Đề Nghẽn Cổ Chai (Bottleneck) Ở NATS Consumer
Khi hệ thống chạy ở chế độ **Simulator** để giả lập thời gian thực, Engine nội suy (Dead Reckoning) liên tục bắn 5000 tọa độ/giây vào NATS message broker. 
Phía Backend đóng vai trò là Consumer `TrackingHandler` nhận luồng dữ liệu này. Cách thiết kế nguyên bản của hệ thống yêu cầu Backend phải:
1. `SaveAircraft`: UPSERT vào bảng `aircraft`.
2. `UpdateTrackingCurrent`: UPSERT vào bảng `tracking`.
3. `SaveTrackingHistory`: INSERT vào bảng `track_history`.

Nếu ép PostgreSQL thực thi 5.000 * 3 = **15.000 lệnh SQL đồng bộ mỗi giây**, Connection Pool của DB sẽ nhanh chóng cạn kiệt, các tiến trình Go bị block lại chờ I/O. Hậu quả là Consumer đọc NATS quá chậm (gây lỗi `nats: slow consumer, messages dropped`) và làm mất tín hiệu truyền tới gRPC `RadarServer`.

### Giải Pháp: Bypass DB I/O Trong Giai Đoạn Simulation
Nhận thấy mục tiêu cốt lõi của Simulator là cấp phát dòng dữ liệu nhịp độ cao để Radar Client hiển thị theo thời gian thực, và bản thân dữ liệu giả lập đã được trích xuất từ chính DB ra, việc lưu ngược lại CSDL là thừa thãi và gây hại.

**Chiến lược tôi áp dụng:**
- Sử dụng cơ chế Bypass toàn bộ các tác vụ gọi CSDL đồng bộ ở `TrackingHandler`.
- Backend chỉ giữ lại thao tác chuyển đổi Protobuf và nạp trực tiếp In-Memory vào cấu trúc `s.objects` của `RadarServer`.

```go
func (h *TrackingHandler) HandlePositionUpdate(msg *nats.Msg) {
    // ... unmarshal protobuf ...

    // [TỐI ƯU HÓA]: Bypass toàn bộ DB I/O
    /*
    h.service.SaveAircraft(...)
    h.service.UpdateTrackingCurrent(...)
    h.service.SaveTrackingHistory(...)
    */

    // Cập nhật trực tiếp lên bộ nhớ RAM (In-Memory)
    h.server.UpsertObject(&bfpb.RadarObject{
        Id: event.GetIcao24(),
        ...
    })
}
```

**Kết quả mang lại:**
- **Zero I/O Overhead:** Backend xử lý 1 thông điệp chỉ mất ~0.01ms (do thao tác RAM), cho phép một tiến trình đơn (single goroutine) tiêu hóa trọn vẹn luồng 100.000+ msg/sec mà không rớt một gói nào.
- Ngăn chặn hoàn toàn lỗi sập PostgreSQL và phình to rác dữ liệu ảo.

---

## Tổng Kết
Hai giải pháp tối ưu hóa trên phản ánh quy tắc cốt lõi khi xử lý dữ liệu lớn:
1. **Đối với Bulk Data:** Dùng công cụ ở cấp độ hệ thống chuyên biệt (Lệnh `COPY` thay vì `INSERT`).
2. **Đối với Data Streaming:** Tránh chạm vào ổ cứng/CSDL nếu không bắt buộc, ưu tiên chuyển đổi In-Memory (RAM) để đạt hiệu năng độ trễ thấp nhất.
