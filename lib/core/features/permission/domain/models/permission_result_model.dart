// ignore_for_file: invalid_annotation_target

import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'permission_result_model.freezed.dart';
part 'permission_result_model.g.dart';

@freezed
sealed class PermissionResultModel with _$PermissionResultModel {
  const factory PermissionResultModel({
    required PermissionType type,
    required PermissionStatus status,
    String? message,
  }) = _PermissionResultModel;

  factory PermissionResultModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionResultModelFromJson(json);
}

extension PermissionResultModelUtilities on PermissionResultModel {
  bool get isGranted =>
      status == PermissionStatus.granted || status == PermissionStatus.limited;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;
  bool get isNotDetermined => status == PermissionStatus.notDetermined;
}
