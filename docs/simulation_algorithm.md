# Phân Tích Thuật Toán Giả Lập Thời Gian Thực (Real-Time Simulation Algorithm)

Tài liệu này trình bày chi tiết về kiến trúc và các thuật toán toán học, tối ưu hoá hệ thống được áp dụng trong mô-đun `HistoricalPoller` và `TrackingHandler` nhằm mô phỏng lại hàng ngàn chuyến bay dân sự với độ trễ thấp (low-latency) và chuyển động mượt mà (continuous movement).

---

## 1. Vấn đề của Dữ liệu Lịch sử (Discrete Data Problem)
Dữ liệu bay thực tế từ OpenSky Network được crawl và lưu vào cơ sở dữ liệu (`track_history`) dưới dạng các "bức ảnh chụp nhanh" (snapshots) rời rạc. Mỗi snapshot cách nhau **10 giây**.
- **Nếu xử lý thô:** Máy bay trên Radar sẽ đứng yên trong 9 giây, và "nhảy cóc" (teleport) đến vị trí mới ở giây thứ 10.
- **Nếu đẩy toàn bộ cùng lúc:** Ở mỗi chu kỳ 10 giây, hệ thống NATS và Database phải gánh hàng ngàn bản ghi cùng lúc, gây ra hiện tượng thắt cổ chai (bottleneck), rớt gói tin (`slow consumer`), và UI bị khựng.

---

## 2. Giải pháp: Thuật toán Nội suy Tọa độ (Dead Reckoning)
Để giải quyết bài toán "nhảy cóc", Simulator không thể đóng vai trò là một "đầu đọc DB" đơn thuần, mà nó phải trở thành một **Vật lý Engine (Physics Engine)** thu nhỏ. 

### Kỹ thuật Dead Reckoning
Dead Reckoning (Dự đoán Vị trí) là thuật toán xác định vị trí hiện tại dựa trên một vị trí đã biết trước đó, kết hợp với vận tốc (Speed) và hướng di chuyển (Heading).

Hệ thống duy trì một vòng lặp nhịp tim (Tick Loop) cứ **1 giây chạy 1 lần**. Ở mỗi nhịp, Engine sẽ tịnh tiến tọa độ của từng máy bay lên phía trước tương ứng với quãng đường bay được trong 1 giây.

### Thuật toán Haversine (Tính toán hình học cầu)
Do Trái Đất là một khối cầu, chúng ta không thể dùng phép cộng tọa độ 2D thông thường (Euclid). Thuật toán **Haversine / Spherical Trigonometry** được triển khai thông qua hàm `movePosition`:

```go
func movePosition(lat, lon, headingDeg, distM float64) (float64, float64) {
	// distM: quãng đường bay được trong 1 giây = Vận tốc (m/s) * 1(s)
	// earthRadiusM = 6371000.0 (Bán kính Trái Đất)
	ang := distM / earthRadiusM
	hr := headingDeg * math.Pi / 180.0  // Chuyển Heading sang Radian
	la := lat * math.Pi / 180.0         // Chuyển Vĩ độ sang Radian
	lo := lon * math.Pi / 180.0         // Chuyển Kinh độ sang Radian

	// Tính Vĩ độ mới (Lat2)
	lat2 := math.Asin(math.Sin(la)*math.Cos(ang) + math.Cos(la)*math.Sin(ang)*math.Cos(hr))
	
	// Tính Kinh độ mới (Lon2)
	lon2 := lo + math.Atan2(
		math.Sin(hr)*math.Sin(ang)*math.Cos(la),
		math.Cos(ang)-math.Sin(la)*math.Sin(lat2),
	)
	
	// Trả về tọa độ theo hệ Độ (Degree)
	return lat2 * 180.0 / math.Pi, lon2 * 180.0 / math.Pi
}
```
**Quy trình kết hợp:**
- Cứ mỗi 1 giây, tính `distM = speed * 1.0` và đưa vào hàm `movePosition` để lấy tọa độ mới.
- Cứ mỗi 10 giây (vòng lặp DB), Simulator tải lại tọa độ thật từ DB để "nắn" lại sai số do Dead Reckoning gây ra và cập nhật vận tốc/hướng gió mới. Nhờ vậy, máy bay vừa bay mượt, vừa bám sát lịch sử gốc!

---

## 3. Thuật toán Trải phẳng Phân phối (Publishing Spreader)
Mặc dù đã chia ra tính toán từng giây, nhưng nếu trong 1 tích tắc của giây đó, Engine đẩy ngay 5000 tin nhắn qua mạng tới NATS, hệ thống vẫn sẽ nghẽn tạm thời. 
**Thuật toán rải đều (Spreading):**
Thay vì vòng lặp `for` đẩy ồ ạt, một khoảng thời gian chờ siêu nhỏ (Micro-sleep) được chèn vào:

```go
// Giới hạn quỹ thời gian đẩy data là 800ms (để dư 200ms cho các tác vụ khác trong 1 giây)
sleepDur := 800 * time.Millisecond / time.Duration(len(flights))

go func(flist []*activeFlight) {
	for _, f := range flist {
		// ... tạo event và publish ...
		p.nc.Publish(subjectFlightPosition, data)
		
		// Ngủ một giấc cực ngắn (vd: 0.16 mili-giây nếu có 5000 chuyến bay)
		time.Sleep(sleepDur)
	}
}(flights)
```
**Hiệu quả:** Lưu lượng tin nhắn được "trải phẳng" (flattened) ra suốt 800 mili-giây. NATS Server chỉ nhận khoảng 6-7 tin nhắn mỗi mili-giây, một con số cực kỳ nhẹ nhàng, triệt tiêu hoàn toàn khả năng nghẽn băng thông.

---

## 4. Tối ưu hóa Database I/O (Bypass Synchronous Upsert)
Ở phía NATS Consumer (tức là `TrackingHandler` của Backend), NATS client mặc định có bộ đệm giới hạn. Nếu Backend xử lý quá chậm, bộ đệm đầy, NATS sẽ ngắt kết nối và báo lỗi `slow consumer`.

**Nút thắt cổ chai (Bottleneck):**
Mỗi tin nhắn bay đến, Backend trước đây phải thực thi các lệnh:
1. `SaveAircraft`: UPSERT vào bảng `aircraft`.
2. `UpdateTrackingCurrent`: UPSERT vào bảng `tracking`.

PostgreSQL không thể gồng gánh 5000 lệnh UPSERT riêng lẻ mỗi giây mà không có Batching. Nó khiến mỗi message tốn vài mili-giây để xử lý.

**Cách giải quyết cho Simulation:**
Vì đây là quá trình **replay** từ `track_history`, bản chất dữ liệu đã lưu trữ an toàn dưới database. Do đó, việc UPSERT ngược lại CSDL mỗi giây là vô nghĩa và tàn phá hiệu suất.
- Tôi đã Disable toàn bộ các hàm gọi Database Synchronous (`SaveAircraft`, `UpdateTrackingCurrent`, `SaveTrackingHistory`).
- Backend chỉ còn làm nhiệm vụ duy nhất: Giải mã ProtoBuf và đẩy In-Memory cập nhật thẳng vào `s.objects` của gRPC `RadarServer`.
- **Kết quả:** Thời gian xử lý 1 message giảm từ ~4ms xuống còn `~0.01ms`. Backend dễ dàng tiêu hóa luồng dữ liệu 5000+ tin nhắn/giây trong suốt quá trình giả lập mà không tốn một chút I/O Disk nào.

---

## 5. Tổng Kết Kiến Trúc Mô Phỏng
Sự kết hợp của **Dead Reckoning** (Nội suy hình học), **Spreading** (Rải đều tải trọng) và **In-Memory Bypass** (Bỏ qua DB I/O) đã biến hệ thống của chúng ta từ việc bị tê liệt khi nhận 18 chuyến bay, trở thành một nền tảng Real-time mạnh mẽ, duy trì liên tục sự luân chuyển mượt mà của hàng nghìn đối tượng bay ở tần số 1 Hz.
