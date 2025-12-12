import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'user_report_model.freezed.dart';

@freezed
sealed class UserReportModel with _$UserReportModel {
  const UserReportModel._();

  const factory UserReportModel({
    required String id,
    required String reportedUserId,
    required String reportedBy,
    required UserReportReason reason,
    required DateTime createdAt,
  }) = _UserReportModel;
}
