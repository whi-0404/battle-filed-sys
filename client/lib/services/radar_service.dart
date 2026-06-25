import 'dart:async';
import 'package:grpc/grpc.dart';
import '../models/radar_object.dart';
import '../proto/battlefield.pb.dart' as bf;
import '../proto/battlefield.pbgrpc.dart'; // exports pbenum types too

class RadarGrpcService {
  static const String _host = 'localhost';
  static const int _grpcPort = 50051;

  ClientChannel? _channel;
  RadarServiceClient? _stub;

  // Dùng StreamController.broadcast() khởi tạo ngay để không miss events
  final StreamController<RadarSnapshotModel> _controller =
      StreamController<RadarSnapshotModel>.broadcast();

  bool _connected = false;

  Stream<RadarSnapshotModel> get stream => _controller.stream;
  bool get isConnected => _connected;

  Future<void> connect() async {
    try {
      _channel = ClientChannel(
        _host,
        port: _grpcPort,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          connectionTimeout: Duration(seconds: 3),
        ),
      );
      _stub = RadarServiceClient(_channel!);

      // Thử ping bằng cách subscribe stream
      final grpcStream = _stub!.streamRadar(bf.StreamRadarRequest());

      // Đợi event đầu tiên để xác nhận kết nối thành công
      bool firstReceived = false;

      grpcStream.listen(
        (snap) {
          if (!firstReceived) {
            firstReceived = true;
            _connected = true;
            print('[radar] gRPC connected to $_host:$_grpcPort');
          }
          _controller.add(RadarSnapshotModel.fromProto(snap));
        },
        onError: (e) {
          print('[radar] gRPC error: $e');
          _connected = false;
          _channel?.shutdown();
        },
        onDone: () {
          _connected = false;
          print('[radar] gRPC stream done');
        },
      );

      // Đợi 5 giây xem có nhận được data không (tăng thời gian chờ)
      await Future.delayed(const Duration(seconds: 5));
      if (!firstReceived) {
        print('[radar] No data from gRPC after 5 seconds. Still waiting...');
        // Đã xoá fallback _startSimulation() ở đây để ép buộc dùng dữ liệu thật
      }
    } catch (e) {
      print('[radar] Cannot connect gRPC: $e');
      // Đã xoá _startSimulation() để không dùng data ảo
    }
  }

  void disconnect() {
    _connected = false;
    _channel?.shutdown();
    // Không close controller để tránh lỗi khi dispose
  }

}
