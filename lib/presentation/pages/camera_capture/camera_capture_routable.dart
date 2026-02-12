import 'package:cloudless/presentation/pages/camera_capture/camera_capture_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'camera_capture_routable.freezed.dart';
part 'camera_capture_routable.g.dart';

@freezed
sealed class CameraCaptureRoutable extends Routable<CameraCaptureRoutable>
    with _$CameraCaptureRoutable {
  factory CameraCaptureRoutable.fromJson(Map<String, dynamic> json) =>
      _$CameraCaptureRoutableFromJson(json);

  const CameraCaptureRoutable._();

  const factory CameraCaptureRoutable() = _CameraCaptureRoutable;

  @override
  String get path => '/camera_capture';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  CameraCaptureRoutable Function(Map<String, dynamic>) get fromMap =>
      CameraCaptureRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, CameraCaptureRoutable routeData) {
    return const CameraCapturePage();
  }
}
