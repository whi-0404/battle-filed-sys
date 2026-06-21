import 'package:flutter/foundation.dart';
import '../models/radar_object.dart';
import '../services/radar_service.dart';
import '../proto/battlefield.pbenum.dart';

class RadarProvider extends ChangeNotifier {
  final RadarGrpcService _service = RadarGrpcService();

  List<RadarObjectModel> _objects = [];
  SnapshotStatsModel _stats = const SnapshotStatsModel();
  DateTime? _lastUpdate;
  bool _connected = false;
  String? _error;
  String _activeFilter = 'ALL';

  List<RadarObjectModel> get objects => _filtered;
  List<RadarObjectModel> get allObjects => _objects;
  SnapshotStatsModel get stats => _stats;
  DateTime? get lastUpdate => _lastUpdate;
  bool get connected => _connected;
  String? get error => _error;
  String get activeFilter => _activeFilter;

  List<RadarObjectModel> get _filtered {
    if (_activeFilter == 'ALL')     return _objects;
    if (_activeFilter == 'CIVIL')   return _objects.where((o) => o.isCivil).toList();
    if (_activeFilter == 'UAV')     return _objects.where((o) => o.type == ObjectType.UAV).toList();
    if (_activeFilter == 'MISSILE') return _objects.where((o) => o.type == ObjectType.MISSILE).toList();
    if (_activeFilter == 'THREAT')  return _objects.where((o) => o.type == ObjectType.THREAT).toList();
    return _objects;
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> connect() async {
    _error = null;

    // Subscribe stream TRƯỚC khi connect để không miss events
    _service.stream.listen(
      (snap) {
        _connected = _service.isConnected;
        _objects = snap.objects;
        _stats = snap.stats;
        _lastUpdate = snap.snapshotAt;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _connected = false;
        notifyListeners();
      },
    );

    // Gọi connect (có thể mất 1-3 giây để fallback sang simulation)
    await _service.connect();

    _connected = _service.isConnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
