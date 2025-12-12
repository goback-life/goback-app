// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'user_report_dto.freezed.dart';
part 'user_report_dto.g.dart';

@freezed
sealed class UserReportDto with _$UserReportDto {
  const factory UserReportDto({
    required String id,
    @JsonKey(name: 'reported_user_id') required String reportedUserId,
    @JsonKey(name: 'reported_by') required String reportedBy,
    required String reason,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _UserReportDto;

  factory UserReportDto.fromJson(Map<String, dynamic> json) =>
      _$UserReportDtoFromJson(json);
}
