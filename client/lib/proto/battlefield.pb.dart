// This is a generated file - do not edit.
//
// Generated from battlefield.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'battlefield.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'battlefield.pbenum.dart';

/// FlightEvent: dữ liệu máy bay dân sự từ OpenSky Network
class FlightEvent extends $pb.GeneratedMessage {
  factory FlightEvent({
    $core.String? icao24,
    $core.String? callsign,
    $core.double? lat,
    $core.double? lon,
    $core.double? alt,
    $core.double? speed,
    $core.double? heading,
    $1.Timestamp? ts,
  }) {
    final result = create();
    if (icao24 != null) result.icao24 = icao24;
    if (callsign != null) result.callsign = callsign;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (alt != null) result.alt = alt;
    if (speed != null) result.speed = speed;
    if (heading != null) result.heading = heading;
    if (ts != null) result.ts = ts;
    return result;
  }

  FlightEvent._();

  factory FlightEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FlightEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlightEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'icao24')
    ..aOS(2, _omitFieldNames ? '' : 'callsign')
    ..aD(3, _omitFieldNames ? '' : 'lat')
    ..aD(4, _omitFieldNames ? '' : 'lon')
    ..aD(5, _omitFieldNames ? '' : 'alt')
    ..aD(6, _omitFieldNames ? '' : 'speed')
    ..aD(7, _omitFieldNames ? '' : 'heading')
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'ts',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlightEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlightEvent copyWith(void Function(FlightEvent) updates) =>
      super.copyWith((message) => updates(message as FlightEvent))
          as FlightEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FlightEvent create() => FlightEvent._();
  @$core.override
  FlightEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FlightEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlightEvent>(create);
  static FlightEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get icao24 => $_getSZ(0);
  @$pb.TagNumber(1)
  set icao24($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIcao24() => $_has(0);
  @$pb.TagNumber(1)
  void clearIcao24() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get callsign => $_getSZ(1);
  @$pb.TagNumber(2)
  set callsign($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCallsign() => $_has(1);
  @$pb.TagNumber(2)
  void clearCallsign() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lat => $_getN(2);
  @$pb.TagNumber(3)
  set lat($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get lon => $_getN(3);
  @$pb.TagNumber(4)
  set lon($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLon() => $_has(3);
  @$pb.TagNumber(4)
  void clearLon() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get alt => $_getN(4);
  @$pb.TagNumber(5)
  set alt($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlt() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get speed => $_getN(5);
  @$pb.TagNumber(6)
  set speed($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSpeed() => $_has(5);
  @$pb.TagNumber(6)
  void clearSpeed() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get heading => $_getN(6);
  @$pb.TagNumber(7)
  set heading($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHeading() => $_has(6);
  @$pb.TagNumber(7)
  void clearHeading() => $_clearField(7);

  @$pb.TagNumber(8)
  $1.Timestamp get ts => $_getN(7);
  @$pb.TagNumber(8)
  set ts($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasTs() => $_has(7);
  @$pb.TagNumber(8)
  void clearTs() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureTs() => $_ensure(7);
}

/// MilitaryEvent: dữ liệu đối tượng quân sự giả lập
class MilitaryEvent extends $pb.GeneratedMessage {
  factory MilitaryEvent({
    $core.String? id,
    ObjectType? type,
    $core.double? lat,
    $core.double? lon,
    $core.double? alt,
    $core.double? heading,
    $core.double? speed,
    ThreatLevel? threatLevel,
    $core.String? status,
    $1.Timestamp? ts,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (alt != null) result.alt = alt;
    if (heading != null) result.heading = heading;
    if (speed != null) result.speed = speed;
    if (threatLevel != null) result.threatLevel = threatLevel;
    if (status != null) result.status = status;
    if (ts != null) result.ts = ts;
    return result;
  }

  MilitaryEvent._();

  factory MilitaryEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MilitaryEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MilitaryEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ObjectType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ObjectType.values)
    ..aD(3, _omitFieldNames ? '' : 'lat')
    ..aD(4, _omitFieldNames ? '' : 'lon')
    ..aD(5, _omitFieldNames ? '' : 'alt')
    ..aD(6, _omitFieldNames ? '' : 'heading')
    ..aD(7, _omitFieldNames ? '' : 'speed')
    ..aE<ThreatLevel>(8, _omitFieldNames ? '' : 'threatLevel',
        enumValues: ThreatLevel.values)
    ..aOS(9, _omitFieldNames ? '' : 'status')
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'ts',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MilitaryEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MilitaryEvent copyWith(void Function(MilitaryEvent) updates) =>
      super.copyWith((message) => updates(message as MilitaryEvent))
          as MilitaryEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MilitaryEvent create() => MilitaryEvent._();
  @$core.override
  MilitaryEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MilitaryEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MilitaryEvent>(create);
  static MilitaryEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ObjectType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ObjectType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lat => $_getN(2);
  @$pb.TagNumber(3)
  set lat($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get lon => $_getN(3);
  @$pb.TagNumber(4)
  set lon($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLon() => $_has(3);
  @$pb.TagNumber(4)
  void clearLon() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get alt => $_getN(4);
  @$pb.TagNumber(5)
  set alt($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlt() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get heading => $_getN(5);
  @$pb.TagNumber(6)
  set heading($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeading() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeading() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get speed => $_getN(6);
  @$pb.TagNumber(7)
  set speed($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSpeed() => $_has(6);
  @$pb.TagNumber(7)
  void clearSpeed() => $_clearField(7);

  @$pb.TagNumber(8)
  ThreatLevel get threatLevel => $_getN(7);
  @$pb.TagNumber(8)
  set threatLevel(ThreatLevel value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasThreatLevel() => $_has(7);
  @$pb.TagNumber(8)
  void clearThreatLevel() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get status => $_getSZ(8);
  @$pb.TagNumber(9)
  set status($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatus() => $_clearField(9);

  @$pb.TagNumber(10)
  $1.Timestamp get ts => $_getN(9);
  @$pb.TagNumber(10)
  set ts($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasTs() => $_has(9);
  @$pb.TagNumber(10)
  void clearTs() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureTs() => $_ensure(9);
}

/// RadarObject: representation thống nhất mọi đối tượng trên radar
class RadarObject extends $pb.GeneratedMessage {
  factory RadarObject({
    $core.String? id,
    ObjectType? type,
    Layer? layer,
    $core.String? callsign,
    $core.double? lat,
    $core.double? lon,
    $core.double? alt,
    $core.double? speed,
    $core.double? heading,
    ThreatLevel? threatLevel,
    $core.String? status,
    $1.Timestamp? lastUpdated,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (layer != null) result.layer = layer;
    if (callsign != null) result.callsign = callsign;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (alt != null) result.alt = alt;
    if (speed != null) result.speed = speed;
    if (heading != null) result.heading = heading;
    if (threatLevel != null) result.threatLevel = threatLevel;
    if (status != null) result.status = status;
    if (lastUpdated != null) result.lastUpdated = lastUpdated;
    return result;
  }

  RadarObject._();

  factory RadarObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RadarObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RadarObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ObjectType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ObjectType.values)
    ..aE<Layer>(3, _omitFieldNames ? '' : 'layer', enumValues: Layer.values)
    ..aOS(4, _omitFieldNames ? '' : 'callsign')
    ..aD(5, _omitFieldNames ? '' : 'lat')
    ..aD(6, _omitFieldNames ? '' : 'lon')
    ..aD(7, _omitFieldNames ? '' : 'alt')
    ..aD(8, _omitFieldNames ? '' : 'speed')
    ..aD(9, _omitFieldNames ? '' : 'heading')
    ..aE<ThreatLevel>(10, _omitFieldNames ? '' : 'threatLevel',
        enumValues: ThreatLevel.values)
    ..aOS(11, _omitFieldNames ? '' : 'status')
    ..aOM<$1.Timestamp>(12, _omitFieldNames ? '' : 'lastUpdated',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RadarObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RadarObject copyWith(void Function(RadarObject) updates) =>
      super.copyWith((message) => updates(message as RadarObject))
          as RadarObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RadarObject create() => RadarObject._();
  @$core.override
  RadarObject createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RadarObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RadarObject>(create);
  static RadarObject? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ObjectType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ObjectType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  Layer get layer => $_getN(2);
  @$pb.TagNumber(3)
  set layer(Layer value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLayer() => $_has(2);
  @$pb.TagNumber(3)
  void clearLayer() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get callsign => $_getSZ(3);
  @$pb.TagNumber(4)
  set callsign($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCallsign() => $_has(3);
  @$pb.TagNumber(4)
  void clearCallsign() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get lat => $_getN(4);
  @$pb.TagNumber(5)
  set lat($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLat() => $_has(4);
  @$pb.TagNumber(5)
  void clearLat() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get lon => $_getN(5);
  @$pb.TagNumber(6)
  set lon($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLon() => $_has(5);
  @$pb.TagNumber(6)
  void clearLon() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get alt => $_getN(6);
  @$pb.TagNumber(7)
  set alt($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlt() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get speed => $_getN(7);
  @$pb.TagNumber(8)
  set speed($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSpeed() => $_has(7);
  @$pb.TagNumber(8)
  void clearSpeed() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get heading => $_getN(8);
  @$pb.TagNumber(9)
  set heading($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHeading() => $_has(8);
  @$pb.TagNumber(9)
  void clearHeading() => $_clearField(9);

  @$pb.TagNumber(10)
  ThreatLevel get threatLevel => $_getN(9);
  @$pb.TagNumber(10)
  set threatLevel(ThreatLevel value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasThreatLevel() => $_has(9);
  @$pb.TagNumber(10)
  void clearThreatLevel() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get status => $_getSZ(10);
  @$pb.TagNumber(11)
  set status($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasStatus() => $_has(10);
  @$pb.TagNumber(11)
  void clearStatus() => $_clearField(11);

  @$pb.TagNumber(12)
  $1.Timestamp get lastUpdated => $_getN(11);
  @$pb.TagNumber(12)
  set lastUpdated($1.Timestamp value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasLastUpdated() => $_has(11);
  @$pb.TagNumber(12)
  void clearLastUpdated() => $_clearField(12);
  @$pb.TagNumber(12)
  $1.Timestamp ensureLastUpdated() => $_ensure(11);
}

/// SnapshotStats: thống kê tổng hợp
class SnapshotStats extends $pb.GeneratedMessage {
  factory SnapshotStats({
    $core.int? totalObjects,
    $core.int? civilAircraft,
    $core.int? uavCount,
    $core.int? missileCount,
    $core.int? threatCount,
    $core.int? criticalThreats,
  }) {
    final result = create();
    if (totalObjects != null) result.totalObjects = totalObjects;
    if (civilAircraft != null) result.civilAircraft = civilAircraft;
    if (uavCount != null) result.uavCount = uavCount;
    if (missileCount != null) result.missileCount = missileCount;
    if (threatCount != null) result.threatCount = threatCount;
    if (criticalThreats != null) result.criticalThreats = criticalThreats;
    return result;
  }

  SnapshotStats._();

  factory SnapshotStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'totalObjects')
    ..aI(2, _omitFieldNames ? '' : 'civilAircraft')
    ..aI(3, _omitFieldNames ? '' : 'uavCount')
    ..aI(4, _omitFieldNames ? '' : 'missileCount')
    ..aI(5, _omitFieldNames ? '' : 'threatCount')
    ..aI(6, _omitFieldNames ? '' : 'criticalThreats')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotStats copyWith(void Function(SnapshotStats) updates) =>
      super.copyWith((message) => updates(message as SnapshotStats))
          as SnapshotStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotStats create() => SnapshotStats._();
  @$core.override
  SnapshotStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SnapshotStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotStats>(create);
  static SnapshotStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get totalObjects => $_getIZ(0);
  @$pb.TagNumber(1)
  set totalObjects($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotalObjects() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalObjects() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get civilAircraft => $_getIZ(1);
  @$pb.TagNumber(2)
  set civilAircraft($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCivilAircraft() => $_has(1);
  @$pb.TagNumber(2)
  void clearCivilAircraft() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get uavCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set uavCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUavCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearUavCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get missileCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set missileCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMissileCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearMissileCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get threatCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set threatCount($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasThreatCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearThreatCount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get criticalThreats => $_getIZ(5);
  @$pb.TagNumber(6)
  set criticalThreats($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCriticalThreats() => $_has(5);
  @$pb.TagNumber(6)
  void clearCriticalThreats() => $_clearField(6);
}

/// RadarSnapshot: payload gửi về client mỗi 100ms
class RadarSnapshot extends $pb.GeneratedMessage {
  factory RadarSnapshot({
    $1.Timestamp? snapshotAt,
    $core.Iterable<RadarObject>? objects,
    SnapshotStats? stats,
  }) {
    final result = create();
    if (snapshotAt != null) result.snapshotAt = snapshotAt;
    if (objects != null) result.objects.addAll(objects);
    if (stats != null) result.stats = stats;
    return result;
  }

  RadarSnapshot._();

  factory RadarSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RadarSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RadarSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..aOM<$1.Timestamp>(1, _omitFieldNames ? '' : 'snapshotAt',
        subBuilder: $1.Timestamp.create)
    ..pPM<RadarObject>(2, _omitFieldNames ? '' : 'objects',
        subBuilder: RadarObject.create)
    ..aOM<SnapshotStats>(3, _omitFieldNames ? '' : 'stats',
        subBuilder: SnapshotStats.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RadarSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RadarSnapshot copyWith(void Function(RadarSnapshot) updates) =>
      super.copyWith((message) => updates(message as RadarSnapshot))
          as RadarSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RadarSnapshot create() => RadarSnapshot._();
  @$core.override
  RadarSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RadarSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RadarSnapshot>(create);
  static RadarSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Timestamp get snapshotAt => $_getN(0);
  @$pb.TagNumber(1)
  set snapshotAt($1.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotAt() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotAt() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Timestamp ensureSnapshotAt() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<RadarObject> get objects => $_getList(1);

  @$pb.TagNumber(3)
  SnapshotStats get stats => $_getN(2);
  @$pb.TagNumber(3)
  set stats(SnapshotStats value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStats() => $_has(2);
  @$pb.TagNumber(3)
  void clearStats() => $_clearField(3);
  @$pb.TagNumber(3)
  SnapshotStats ensureStats() => $_ensure(2);
}

/// StreamRadarRequest: request từ client (hiện tại trống, có thể thêm filter sau)
class StreamRadarRequest extends $pb.GeneratedMessage {
  factory StreamRadarRequest() => create();

  StreamRadarRequest._();

  factory StreamRadarRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamRadarRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamRadarRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'battlefield'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamRadarRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamRadarRequest copyWith(void Function(StreamRadarRequest) updates) =>
      super.copyWith((message) => updates(message as StreamRadarRequest))
          as StreamRadarRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamRadarRequest create() => StreamRadarRequest._();
  @$core.override
  StreamRadarRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamRadarRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamRadarRequest>(create);
  static StreamRadarRequest? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
