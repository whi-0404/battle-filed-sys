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

class ObjectType extends $pb.ProtobufEnum {
  static const ObjectType OBJECT_TYPE_UNSPECIFIED =
      ObjectType._(0, _omitEnumNames ? '' : 'OBJECT_TYPE_UNSPECIFIED');
  static const ObjectType UAV = ObjectType._(1, _omitEnumNames ? '' : 'UAV');
  static const ObjectType MISSILE =
      ObjectType._(2, _omitEnumNames ? '' : 'MISSILE');
  static const ObjectType THREAT =
      ObjectType._(3, _omitEnumNames ? '' : 'THREAT');

  static const $core.List<ObjectType> values = <ObjectType>[
    OBJECT_TYPE_UNSPECIFIED,
    UAV,
    MISSILE,
    THREAT,
  ];

  static final $core.List<ObjectType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ObjectType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ObjectType._(super.value, super.name);
}

class ThreatLevel extends $pb.ProtobufEnum {
  static const ThreatLevel THREAT_LEVEL_UNSPECIFIED =
      ThreatLevel._(0, _omitEnumNames ? '' : 'THREAT_LEVEL_UNSPECIFIED');
  static const ThreatLevel LOW = ThreatLevel._(1, _omitEnumNames ? '' : 'LOW');
  static const ThreatLevel MEDIUM =
      ThreatLevel._(2, _omitEnumNames ? '' : 'MEDIUM');
  static const ThreatLevel HIGH =
      ThreatLevel._(3, _omitEnumNames ? '' : 'HIGH');
  static const ThreatLevel CRITICAL =
      ThreatLevel._(4, _omitEnumNames ? '' : 'CRITICAL');

  static const $core.List<ThreatLevel> values = <ThreatLevel>[
    THREAT_LEVEL_UNSPECIFIED,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL,
  ];

  static final $core.List<ThreatLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ThreatLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ThreatLevel._(super.value, super.name);
}

/// Layer phân biệt nguồn gốc đối tượng
class Layer extends $pb.ProtobufEnum {
  static const Layer LAYER_UNSPECIFIED =
      Layer._(0, _omitEnumNames ? '' : 'LAYER_UNSPECIFIED');
  static const Layer CIVIL = Layer._(1, _omitEnumNames ? '' : 'CIVIL');
  static const Layer MILITARY = Layer._(2, _omitEnumNames ? '' : 'MILITARY');

  static const $core.List<Layer> values = <Layer>[
    LAYER_UNSPECIFIED,
    CIVIL,
    MILITARY,
  ];

  static final $core.List<Layer?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Layer? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Layer._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
