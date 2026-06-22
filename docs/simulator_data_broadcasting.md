# Cơ Chế Phát Dữ Liệu Của Simulator Tới Backend Và Client

Tài liệu này phân tích chi tiết con đường một thông điệp (Message) đi từ lúc được sinh ra bên trong lòng hệ thống Simulator, tới khi lướt qua mạng diện rộng để đến tay Backend, và đích đến cuối cùng là giao diện Client.

---

## 1. Trái Tim Của Simulator (Sinh Sự Kiện)

Simulator bao gồm hai cỗ máy chính (Engines) chuyên sinh ra tọa độ ảo:
- **HistoricalPoller (Dân Sự):** Sinh tọa độ của 5000+ chiếc máy bay dựa trên thuật toán Dead Reckoning.
- **MilitaryEngines (Quân Sự):** Sinh tọa độ của UAV, Tên lửa đánh chặn và Mục tiêu đe dọa.

Khi một tọa độ mới được xác định, hệ thống sẽ gom nó vào một struct có tên là `FlightEvent` (cho dân sự) hoặc `MilitaryEvent` (cho quân sự). 

Ví dụ với `FlightEvent`:
```go
event := &bfpb.FlightEvent{
    Icao24:   f.icao24,
    Callsign: f.callsign,
    Lat:      f.lat,
    Lon:      f.lon,
    Alt:      f.alt,
    Speed:    f.speed,
    Heading:  f.heading,
    Ts:       timestamppb.New(time.Now()), // Đóng dấu thời gian thực
}
```

---

## 2. Nén Dữ Liệu Nhị Phân (Protobuf Serialization)

Bạn không thể ném thẳng một Struct của Go qua mạng TCP được. Lệnh `proto.Marshal(event)` được gọi ra để "ép" toàn bộ các thuộc tính của `event` trên thành một chuỗi Mảng Byte siêu nén (Binary Payload).
Chuỗi Byte này không chứa các Text dư thừa nên nó cực kỳ nhẹ (chỉ khoảng vài chục byte cho một chuyến bay).

```go
data, err := proto.Marshal(event)
```

---

## 3. Thuật Toán Trải Phẳng Lưu Lượng (Traffic Spreader)

Đây là vũ khí bí mật giúp Backend không bao giờ bị nghẽn (Tránh lỗi `slow consumer`).
Với 5000 máy bay, nếu vòng lặp `for` nổ súng liên thanh đẩy 5000 cục data qua mạng ở cùng một mili-giây, Router mạng và NATS Server sẽ bị chớp nháy (Spike).

Simulator chia đều việc bắn 5000 tin nhắn ra một khoảng thời gian 800 mili-giây. Nó làm việc này bằng một lệnh ru ngủ siêu tốc:
```go
sleepDur := 800 * time.Millisecond / time.Duration(len(flights))

for _, f := range flist {
    // Bắn 1 viên đạn (data)
    p.nc.Publish(subjectFlightPosition, data)
    
    // Ngủ một lúc (ví dụ: 0.16ms) rồi mới bắn viên tiếp theo
    time.Sleep(sleepDur)
}
```

---

## 4. Trạm Trung Chuyển NATS (Message Broker)

Khi lệnh `nc.Publish()` được gọi, mảng byte nhị phân được truyền qua giao thức TCP tới NATS Server trên 2 ống nối (Topic) riêng biệt:
- **Dân sự:** Topic `flight.position.updated`
- **Quân sự:** Topic `military.position.updated`

NATS Broker không hề phân tích nội dung byte này, nhiệm vụ của nó chỉ là: "Ai đăng ký kênh này thì tao quăng data sang cho người đó!".

---

## 5. Backend Bắt Bóng (Data Consumption)

Bên kia chiến tuyến, Server Backend có gắn sẵn các "kẻ nghe lén" (`TrackingHandler` và `MilitaryHandler`).
Khi một mảng Byte rơi vào phễu của chúng:
1. Chúng gỡ băng dính nhị phân ra (`proto.Unmarshal`) để trả nó về hình hài cái Struct ban đầu.
2. Chúng lập tức cầm cái Struct này, nhét thẳng vào một biến RAM siêu to khổng lồ tên là `s.objects` (của `RadarServer`).

*(Lưu ý: Quá trình này hoàn toàn diễn ra trong RAM (In-Memory), không có bất kỳ lệnh SQL nào can thiệp nên tốc độ nhanh như chớp).*

---

## 6. Lên Đường Sang Client (gRPC Streaming)

Cứ mỗi 100 mili-giây, `RadarServer` sẽ gom toàn bộ các đối tượng đang có mặt trong biến `s.objects` thành một bức ảnh chụp nhanh (`RadarSnapshot`).
Bức ảnh này cũng được nén thành chuỗi nhị phân Protobuf, và tống thẳng vào ống nước `stream.Send(snapshot)` của gRPC.

Ở đầu dây bên kia (App Flutter), ống nước được nối sẵn. Nó hứng lấy Snapshot, bung nén ra thành các Icon máy bay và vẽ chúng lên `FlutterMap`. 

**Tổng kết:** Một sự kiện bay sinh ra từ Simulator, được nén, trải đều, chui qua NATS, vào RAM Backend, bị gom lại, và trượt dọc qua ống gRPC HTTP/2 xuống điện thoại của bạn với tổng độ trễ chưa đầy `15ms`. Một hệ thống thời gian thực hoàn hảo!
