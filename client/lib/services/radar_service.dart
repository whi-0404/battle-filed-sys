import 'dart:async';
import 'dart:math' as math;
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
  Timer? _simTimer;
  final Map<String, _SimObject> _simObjects = {};
  final math.Random _rand = math.Random();

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
          print('[radar] gRPC error → simulation: $e');
          _connected = false;
          _channel?.shutdown();
          _startSimulation();
        },
        onDone: () {
          _connected = false;
          print('[radar] gRPC stream done');
        },
      );

      // Đợi 1 giây xem có nhận được data không
      await Future.delayed(const Duration(seconds: 1));
      if (!firstReceived) {
        print('[radar] No data from gRPC → simulation mode');
        _channel?.shutdown();
        _startSimulation();
      }
    } catch (e) {
      print('[radar] Cannot connect → simulation: $e');
      _startSimulation();
    }
  }

  void disconnect() {
    _connected = false;
    _simTimer?.cancel();
    _channel?.shutdown();
    // Không close controller để tránh lỗi khi dispose
  }

  // ─── Simulation ───────────────────────────────────────────────────

  void _startSimulation() {
    if (_connected) return; // đã connect rồi thì không sim
    _connected = true;
    print('[radar] Simulation started with ${_simObjects.isEmpty ? "new" : "existing"} objects');

    if (_simObjects.isEmpty) _initObjects();

    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      for (final o in _simObjects.values) {
        o.move();
      }
      if (!_controller.isClosed) {
        _controller.add(_buildSnapshot());
      }
    });
  }

  void _initObjects() {
    // Dùng math.Random thật, với seed khác nhau cho từng object
    final callsigns = ['VN123', 'QH204', 'VJ315', 'BL401', 'VU512',
                       'SQ811', 'CX384', 'MH370', 'AK123', 'TG905'];

    // Civil aircraft
    for (int i = 0; i < 8; i++) {
      final id = 'ICAO${(i + 1).toString().padLeft(4, '0')}';
      _simObjects[id] = _SimObject(
        id: id, type: 'AIRCRAFT', layer: 'CIVIL',
        callsign: callsigns[i % callsigns.length],
        lat: 10.0 + _rand.nextDouble() * 13.0,
        lon: 103.0 + _rand.nextDouble() * 6.0,
        alt: 8000.0 + _rand.nextDouble() * 3000.0,
        speed: 400.0 + _rand.nextDouble() * 150.0,
        heading: _rand.nextDouble() * 360.0,
        threatLevel: 'UNSPECIFIED',
      );
    }

    // UAV
    for (int i = 0; i < 12; i++) {
      final id = 'UAV-${(i + 1).toString().padLeft(3, '0')}';
      _simObjects[id] = _SimObject(
        id: id, type: 'UAV', layer: 'MILITARY',
        callsign: id,
        lat: 9.0 + _rand.nextDouble() * 14.0,
        lon: 102.5 + _rand.nextDouble() * 7.0,
        alt: 500.0 + _rand.nextDouble() * 4500.0,
        speed: 80.0 + _rand.nextDouble() * 120.0,
        heading: _rand.nextDouble() * 360.0,
        threatLevel: 'LOW',
      );
    }

    // Missiles
    for (int i = 0; i < 4; i++) {
      final id = 'MSL-${(i + 1).toString().padLeft(3, '0')}';
      _simObjects[id] = _SimObject(
        id: id, type: 'MISSILE', layer: 'MILITARY',
        callsign: id,
        lat: 9.0 + _rand.nextDouble() * 14.0,
        lon: 102.5 + _rand.nextDouble() * 7.0,
        alt: 3000.0 + _rand.nextDouble() * 7000.0,
        speed: 600.0 + _rand.nextDouble() * 400.0,
        heading: _rand.nextDouble() * 360.0,
        threatLevel: 'CRITICAL',
      );
    }

    // Threats
    const levels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'HIGH', 'MEDIUM'];
    for (int i = 0; i < 6; i++) {
      final id = 'THR-${(i + 1).toString().padLeft(3, '0')}';
      _simObjects[id] = _SimObject(
        id: id, type: 'THREAT', layer: 'MILITARY',
        callsign: id,
        lat: 9.0 + _rand.nextDouble() * 14.0,
        lon: 102.5 + _rand.nextDouble() * 7.0,
        alt: 100.0 + _rand.nextDouble() * 7900.0,
        speed: 50.0 + _rand.nextDouble() * 250.0,
        heading: _rand.nextDouble() * 360.0,
        threatLevel: levels[i],
      );
    }

    print('[radar] Initialized ${_simObjects.length} simulation objects');
  }

  RadarSnapshotModel _buildSnapshot() {
    final objs = _simObjects.values.map((s) => RadarObjectModel.fromJson({
      'id': s.id, 'type': s.type, 'layer': s.layer,
      'callsign': s.callsign, 'lat': s.lat, 'lon': s.lon,
      'alt': s.alt, 'speed': s.speed, 'heading': s.heading,
      'threat_level': s.threatLevel, 'status': 'ACTIVE',
      'last_updated': DateTime.now().toIso8601String(),
    })).toList();

    int civil = 0, uav = 0, missile = 0, threat = 0, crit = 0;
    for (final o in objs) {
      if (o.isCivil) { civil++; continue; }
      if (o.type == ObjectType.UAV)     { uav++; continue; }
      if (o.type == ObjectType.MISSILE) { missile++; continue; }
      if (o.type == ObjectType.THREAT) {
        threat++;
        if (o.threatLevel == ThreatLevel.CRITICAL ||
            o.threatLevel == ThreatLevel.HIGH) crit++;
      }
    }

    return RadarSnapshotModel(
      snapshotAt: DateTime.now(),
      objects: objs,
      stats: SnapshotStatsModel(
        totalObjects: objs.length,
        civilAircraft: civil, uavCount: uav,
        missileCount: missile, threatCount: threat,
        criticalThreats: crit,
      ),
    );
  }
}

// ─── Simulation Object ────────────────────────────────────────────

class _SimObject {
  final String id, type, layer, callsign, threatLevel;
  double lat, lon, alt, speed, heading;
  final math.Random _rng = math.Random();

  _SimObject({
    required this.id, required this.type, required this.layer,
    required this.callsign, required this.threatLevel,
    required this.lat, required this.lon, required this.alt,
    required this.speed, required this.heading,
  });

  void move() {
    const dt = 0.1 / 3600.0; // 100ms in hours
    final distKm = speed * 1.852 * dt;
    final ang = distKm / 6371.0; // angular distance in radians
    final hr = heading * math.pi / 180.0;
    final la = lat * math.pi / 180.0;
    final lo = lon * math.pi / 180.0;

    final lat2 = math.asin(
      math.sin(la) * math.cos(ang) +
      math.cos(la) * math.sin(ang) * math.cos(hr),
    );
    final lon2 = lo + math.atan2(
      math.sin(hr) * math.sin(ang) * math.cos(la),
      math.cos(ang) - math.sin(la) * math.sin(lat2),
    );

    final nl = lat2 * 180.0 / math.pi;
    final nn = lon2 * 180.0 / math.pi;

    // Bounce khi ra khỏi vùng chiến trường VN + vùng lân cận
    if (nl < 8.5 || nl > 23.5 || nn < 102.0 || nn > 110.0) {
      heading = (heading + 170 + _rng.nextDouble() * 20) % 360;
    } else {
      lat = nl;
      lon = nn;
    }

    // Thêm drift nhỏ ngẫu nhiên để di chuyển tự nhiên hơn
    heading = (heading + (_rng.nextDouble() - 0.5) * 2.0) % 360;
  }
}
