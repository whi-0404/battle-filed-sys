// This is a generated file - do not edit.
//
// Generated from battlefield.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use objectTypeDescriptor instead')
const ObjectType$json = {
  '1': 'ObjectType',
  '2': [
    {'1': 'OBJECT_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'UAV', '2': 1},
    {'1': 'MISSILE', '2': 2},
    {'1': 'THREAT', '2': 3},
  ],
};

/// Descriptor for `ObjectType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List objectTypeDescriptor = $convert.base64Decode(
    'CgpPYmplY3RUeXBlEhsKF09CSkVDVF9UWVBFX1VOU1BFQ0lGSUVEEAASBwoDVUFWEAESCwoHTU'
    'lTU0lMRRACEgoKBlRIUkVBVBAD');

@$core.Deprecated('Use threatLevelDescriptor instead')
const ThreatLevel$json = {
  '1': 'ThreatLevel',
  '2': [
    {'1': 'THREAT_LEVEL_UNSPECIFIED', '2': 0},
    {'1': 'LOW', '2': 1},
    {'1': 'MEDIUM', '2': 2},
    {'1': 'HIGH', '2': 3},
    {'1': 'CRITICAL', '2': 4},
  ],
};

/// Descriptor for `ThreatLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List threatLevelDescriptor = $convert.base64Decode(
    'CgtUaHJlYXRMZXZlbBIcChhUSFJFQVRfTEVWRUxfVU5TUEVDSUZJRUQQABIHCgNMT1cQARIKCg'
    'ZNRURJVU0QAhIICgRISUdIEAMSDAoIQ1JJVElDQUwQBA==');

@$core.Deprecated('Use layerDescriptor instead')
const Layer$json = {
  '1': 'Layer',
  '2': [
    {'1': 'LAYER_UNSPECIFIED', '2': 0},
    {'1': 'CIVIL', '2': 1},
    {'1': 'MILITARY', '2': 2},
  ],
};

/// Descriptor for `Layer`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List layerDescriptor = $convert.base64Decode(
    'CgVMYXllchIVChFMQVlFUl9VTlNQRUNJRklFRBAAEgkKBUNJVklMEAESDAoITUlMSVRBUlkQAg'
    '==');

@$core.Deprecated('Use flightEventDescriptor instead')
const FlightEvent$json = {
  '1': 'FlightEvent',
  '2': [
    {'1': 'icao24', '3': 1, '4': 1, '5': 9, '10': 'icao24'},
    {'1': 'callsign', '3': 2, '4': 1, '5': 9, '10': 'callsign'},
    {'1': 'lat', '3': 3, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 4, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'alt', '3': 5, '4': 1, '5': 1, '10': 'alt'},
    {'1': 'speed', '3': 6, '4': 1, '5': 1, '10': 'speed'},
    {'1': 'heading', '3': 7, '4': 1, '5': 1, '10': 'heading'},
    {
      '1': 'ts',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'ts'
    },
  ],
};

/// Descriptor for `FlightEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flightEventDescriptor = $convert.base64Decode(
    'CgtGbGlnaHRFdmVudBIWCgZpY2FvMjQYASABKAlSBmljYW8yNBIaCghjYWxsc2lnbhgCIAEoCV'
    'IIY2FsbHNpZ24SEAoDbGF0GAMgASgBUgNsYXQSEAoDbG9uGAQgASgBUgNsb24SEAoDYWx0GAUg'
    'ASgBUgNhbHQSFAoFc3BlZWQYBiABKAFSBXNwZWVkEhgKB2hlYWRpbmcYByABKAFSB2hlYWRpbm'
    'cSKgoCdHMYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgJ0cw==');

@$core.Deprecated('Use militaryEventDescriptor instead')
const MilitaryEvent$json = {
  '1': 'MilitaryEvent',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.battlefield.ObjectType',
      '10': 'type'
    },
    {'1': 'lat', '3': 3, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 4, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'alt', '3': 5, '4': 1, '5': 1, '10': 'alt'},
    {'1': 'heading', '3': 6, '4': 1, '5': 1, '10': 'heading'},
    {'1': 'speed', '3': 7, '4': 1, '5': 1, '10': 'speed'},
    {
      '1': 'threat_level',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.battlefield.ThreatLevel',
      '10': 'threatLevel'
    },
    {'1': 'status', '3': 9, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'ts',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'ts'
    },
  ],
};

/// Descriptor for `MilitaryEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List militaryEventDescriptor = $convert.base64Decode(
    'Cg1NaWxpdGFyeUV2ZW50Eg4KAmlkGAEgASgJUgJpZBIrCgR0eXBlGAIgASgOMhcuYmF0dGxlZm'
    'llbGQuT2JqZWN0VHlwZVIEdHlwZRIQCgNsYXQYAyABKAFSA2xhdBIQCgNsb24YBCABKAFSA2xv'
    'bhIQCgNhbHQYBSABKAFSA2FsdBIYCgdoZWFkaW5nGAYgASgBUgdoZWFkaW5nEhQKBXNwZWVkGA'
    'cgASgBUgVzcGVlZBI7Cgx0aHJlYXRfbGV2ZWwYCCABKA4yGC5iYXR0bGVmaWVsZC5UaHJlYXRM'
    'ZXZlbFILdGhyZWF0TGV2ZWwSFgoGc3RhdHVzGAkgASgJUgZzdGF0dXMSKgoCdHMYCiABKAsyGi'
    '5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgJ0cw==');

@$core.Deprecated('Use radarObjectDescriptor instead')
const RadarObject$json = {
  '1': 'RadarObject',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.battlefield.ObjectType',
      '10': 'type'
    },
    {
      '1': 'layer',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.battlefield.Layer',
      '10': 'layer'
    },
    {'1': 'callsign', '3': 4, '4': 1, '5': 9, '10': 'callsign'},
    {'1': 'lat', '3': 5, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 6, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'alt', '3': 7, '4': 1, '5': 1, '10': 'alt'},
    {'1': 'speed', '3': 8, '4': 1, '5': 1, '10': 'speed'},
    {'1': 'heading', '3': 9, '4': 1, '5': 1, '10': 'heading'},
    {
      '1': 'threat_level',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.battlefield.ThreatLevel',
      '10': 'threatLevel'
    },
    {'1': 'status', '3': 11, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'last_updated',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUpdated'
    },
  ],
};

/// Descriptor for `RadarObject`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List radarObjectDescriptor = $convert.base64Decode(
    'CgtSYWRhck9iamVjdBIOCgJpZBgBIAEoCVICaWQSKwoEdHlwZRgCIAEoDjIXLmJhdHRsZWZpZW'
    'xkLk9iamVjdFR5cGVSBHR5cGUSKAoFbGF5ZXIYAyABKA4yEi5iYXR0bGVmaWVsZC5MYXllclIF'
    'bGF5ZXISGgoIY2FsbHNpZ24YBCABKAlSCGNhbGxzaWduEhAKA2xhdBgFIAEoAVIDbGF0EhAKA2'
    'xvbhgGIAEoAVIDbG9uEhAKA2FsdBgHIAEoAVIDYWx0EhQKBXNwZWVkGAggASgBUgVzcGVlZBIY'
    'CgdoZWFkaW5nGAkgASgBUgdoZWFkaW5nEjsKDHRocmVhdF9sZXZlbBgKIAEoDjIYLmJhdHRsZW'
    'ZpZWxkLlRocmVhdExldmVsUgt0aHJlYXRMZXZlbBIWCgZzdGF0dXMYCyABKAlSBnN0YXR1cxI9'
    'CgxsYXN0X3VwZGF0ZWQYDCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtsYXN0VX'
    'BkYXRlZA==');

@$core.Deprecated('Use snapshotStatsDescriptor instead')
const SnapshotStats$json = {
  '1': 'SnapshotStats',
  '2': [
    {'1': 'total_objects', '3': 1, '4': 1, '5': 5, '10': 'totalObjects'},
    {'1': 'civil_aircraft', '3': 2, '4': 1, '5': 5, '10': 'civilAircraft'},
    {'1': 'uav_count', '3': 3, '4': 1, '5': 5, '10': 'uavCount'},
    {'1': 'missile_count', '3': 4, '4': 1, '5': 5, '10': 'missileCount'},
    {'1': 'threat_count', '3': 5, '4': 1, '5': 5, '10': 'threatCount'},
    {'1': 'critical_threats', '3': 6, '4': 1, '5': 5, '10': 'criticalThreats'},
  ],
};

/// Descriptor for `SnapshotStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotStatsDescriptor = $convert.base64Decode(
    'Cg1TbmFwc2hvdFN0YXRzEiMKDXRvdGFsX29iamVjdHMYASABKAVSDHRvdGFsT2JqZWN0cxIlCg'
    '5jaXZpbF9haXJjcmFmdBgCIAEoBVINY2l2aWxBaXJjcmFmdBIbCgl1YXZfY291bnQYAyABKAVS'
    'CHVhdkNvdW50EiMKDW1pc3NpbGVfY291bnQYBCABKAVSDG1pc3NpbGVDb3VudBIhCgx0aHJlYX'
    'RfY291bnQYBSABKAVSC3RocmVhdENvdW50EikKEGNyaXRpY2FsX3RocmVhdHMYBiABKAVSD2Ny'
    'aXRpY2FsVGhyZWF0cw==');

@$core.Deprecated('Use radarSnapshotDescriptor instead')
const RadarSnapshot$json = {
  '1': 'RadarSnapshot',
  '2': [
    {
      '1': 'snapshot_at',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'snapshotAt'
    },
    {
      '1': 'objects',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.battlefield.RadarObject',
      '10': 'objects'
    },
    {
      '1': 'stats',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.battlefield.SnapshotStats',
      '10': 'stats'
    },
  ],
};

/// Descriptor for `RadarSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List radarSnapshotDescriptor = $convert.base64Decode(
    'Cg1SYWRhclNuYXBzaG90EjsKC3NuYXBzaG90X2F0GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLl'
    'RpbWVzdGFtcFIKc25hcHNob3RBdBIyCgdvYmplY3RzGAIgAygLMhguYmF0dGxlZmllbGQuUmFk'
    'YXJPYmplY3RSB29iamVjdHMSMAoFc3RhdHMYAyABKAsyGi5iYXR0bGVmaWVsZC5TbmFwc2hvdF'
    'N0YXRzUgVzdGF0cw==');

@$core.Deprecated('Use streamRadarRequestDescriptor instead')
const StreamRadarRequest$json = {
  '1': 'StreamRadarRequest',
};

/// Descriptor for `StreamRadarRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamRadarRequestDescriptor =
    $convert.base64Decode('ChJTdHJlYW1SYWRhclJlcXVlc3Q=');
