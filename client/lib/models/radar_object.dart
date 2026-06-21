// Import generated proto types
import '../proto/battlefield.pb.dart' as proto;
import '../proto/battlefield.pbenum.dart';

// Re-export enums – files importing this also get ObjectType, ThreatLevel, Layer
export '../proto/battlefield.pbenum.dart' show ObjectType, ThreatLevel, Layer;

// ─── Domain model ─────────────────────────────────────────────────

class RadarObjectModel {
  final String id;
  final ObjectType type;
  final Layer layer;
  final String callsign;
  final double lat;
  final double lon;
  final double alt;
  final double speed;
  final double heading;
  final ThreatLevel threatLevel;
  final String status;
  final DateTime lastUpdated;

  const RadarObjectModel({
    required this.id,
    required this.type,
    required this.layer,
    required this.callsign,
    required this.lat,
    required this.lon,
    required this.alt,
    required this.speed,
    required this.heading,
    required this.threatLevel,
    required this.status,
    required this.lastUpdated,
  });

  /// Từ proto generated RadarObject
  factory RadarObjectModel.fromProto(proto.RadarObject p) {
    return RadarObjectModel(
      id: p.id,
      type: p.type,
      layer: p.layer,
      callsign: p.callsign,
      lat: p.lat,
      lon: p.lon,
      alt: p.alt,
      speed: p.speed,
      heading: p.heading,
      threatLevel: p.threatLevel,
      status: p.status,
      lastUpdated: p.lastUpdated.toDateTime(),
    );
  }

  /// Từ JSON map (dùng cho simulation mode)
  factory RadarObjectModel.fromJson(Map<String, dynamic> json) {
    return RadarObjectModel(
      id: json['id'] ?? '',
      type: _parseType(json['type']),
      layer: _parseLayer(json['layer']),
      callsign: json['callsign'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      alt: (json['alt'] ?? 0.0).toDouble(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      heading: (json['heading'] ?? 0.0).toDouble(),
      threatLevel: _parseThreatLevel(json['threat_level']),
      status: json['status'] ?? 'ACTIVE',
      lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  static ObjectType _parseType(dynamic v) {
    switch (v) {
      case 'UAV':     return ObjectType.UAV;
      case 'MISSILE': return ObjectType.MISSILE;
      case 'THREAT':  return ObjectType.THREAT;
      default:        return ObjectType.OBJECT_TYPE_UNSPECIFIED;
    }
  }

  static Layer _parseLayer(dynamic v) {
    switch (v) {
      case 'CIVIL':    return Layer.CIVIL;
      case 'MILITARY': return Layer.MILITARY;
      default:         return Layer.LAYER_UNSPECIFIED;
    }
  }

  static ThreatLevel _parseThreatLevel(dynamic v) {
    switch (v) {
      case 'LOW':      return ThreatLevel.LOW;
      case 'MEDIUM':   return ThreatLevel.MEDIUM;
      case 'HIGH':     return ThreatLevel.HIGH;
      case 'CRITICAL': return ThreatLevel.CRITICAL;
      default:         return ThreatLevel.THREAT_LEVEL_UNSPECIFIED;
    }
  }

  String get displayName =>
      callsign.isNotEmpty && callsign.trim() != id ? callsign.trim() : id;

  bool get isCivil    => layer == Layer.CIVIL;
  bool get isMilitary => layer == Layer.MILITARY;

  String get typeLabel {
    if (isCivil) return 'Aircraft';
    if (type == ObjectType.UAV)     return 'UAV';
    if (type == ObjectType.MISSILE) return 'Missile';
    if (type == ObjectType.THREAT)  return 'Threat';
    return 'Unknown';
  }
}

// ─── Snapshot wrapper ─────────────────────────────────────────────

class RadarSnapshotModel {
  final DateTime snapshotAt;
  final List<RadarObjectModel> objects;
  final SnapshotStatsModel stats;

  const RadarSnapshotModel({
    required this.snapshotAt,
    required this.objects,
    required this.stats,
  });

  factory RadarSnapshotModel.fromProto(proto.RadarSnapshot p) {
    return RadarSnapshotModel(
      snapshotAt: p.snapshotAt.toDateTime(),
      objects: p.objects.map(RadarObjectModel.fromProto).toList(),
      stats: SnapshotStatsModel.fromProto(p.stats),
    );
  }
}

class SnapshotStatsModel {
  final int totalObjects;
  final int civilAircraft;
  final int uavCount;
  final int missileCount;
  final int threatCount;
  final int criticalThreats;

  const SnapshotStatsModel({
    this.totalObjects = 0,
    this.civilAircraft = 0,
    this.uavCount = 0,
    this.missileCount = 0,
    this.threatCount = 0,
    this.criticalThreats = 0,
  });

  factory SnapshotStatsModel.fromProto(proto.SnapshotStats p) {
    return SnapshotStatsModel(
      totalObjects: p.totalObjects,
      civilAircraft: p.civilAircraft,
      uavCount: p.uavCount,
      missileCount: p.missileCount,
      threatCount: p.threatCount,
      criticalThreats: p.criticalThreats,
    );
  }
}
