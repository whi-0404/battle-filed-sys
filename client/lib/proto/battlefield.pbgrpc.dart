// This is a generated file - do not edit.
//
// Generated from battlefield.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'battlefield.pb.dart' as $0;

export 'battlefield.pb.dart';

/// RadarService: gRPC service cho real-time radar streaming
@$pb.GrpcServiceName('battlefield.RadarService')
class RadarServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  RadarServiceClient(super.channel, {super.options, super.interceptors});

  /// StreamRadar: server-streaming RPC, push RadarSnapshot mỗi 100ms
  $grpc.ResponseStream<$0.RadarSnapshot> streamRadar(
    $0.StreamRadarRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamRadar, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$streamRadar =
      $grpc.ClientMethod<$0.StreamRadarRequest, $0.RadarSnapshot>(
          '/battlefield.RadarService/StreamRadar',
          ($0.StreamRadarRequest value) => value.writeToBuffer(),
          $0.RadarSnapshot.fromBuffer);
}

@$pb.GrpcServiceName('battlefield.RadarService')
abstract class RadarServiceBase extends $grpc.Service {
  $core.String get $name => 'battlefield.RadarService';

  RadarServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StreamRadarRequest, $0.RadarSnapshot>(
        'StreamRadar',
        streamRadar_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.StreamRadarRequest.fromBuffer(value),
        ($0.RadarSnapshot value) => value.writeToBuffer()));
  }

  $async.Stream<$0.RadarSnapshot> streamRadar_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StreamRadarRequest> $request) async* {
    yield* streamRadar($call, await $request);
  }

  $async.Stream<$0.RadarSnapshot> streamRadar(
      $grpc.ServiceCall call, $0.StreamRadarRequest request);
}
