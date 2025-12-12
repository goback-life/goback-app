import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'post_report_model.freezed.dart';

@freezed
sealed class PostReportModel with _$PostReportModel {
  const PostReportModel._();

  const factory PostReportModel({
    required String id,
    required String postId,
    required String reportedBy,
    required PostReportReason reason,
    required DateTime createdAt,
  }) = _PostReportModel;
}
