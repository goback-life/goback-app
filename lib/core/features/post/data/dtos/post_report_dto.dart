// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_report_dto.freezed.dart';
part 'post_report_dto.g.dart';

@freezed
sealed class PostReportDto with _$PostReportDto {
  const factory PostReportDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'reported_by') required String reportedBy,
    required String reason,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _PostReportDto;

  factory PostReportDto.fromJson(Map<String, dynamic> json) =>
      _$PostReportDtoFromJson(json);
}
