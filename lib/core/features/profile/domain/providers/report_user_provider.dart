import 'package:cloudless/core/features/profile/data/providers/user_report_service_provider.dart';
import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/core/features/profile/domain/models/user_report_model.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/report_user_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_user_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<UserReportModel>> reportUser(
  Ref ref, {
  required String reportedUserId,
  required String reportedBy,
  required UserReportReason reason,
}) async {
  final useCase =
      ReportUserUseCase(
        service: ref.watch(userReportServiceProvider),
      ).withReportData(
        reportedUserId: reportedUserId,
        reportedBy: reportedBy,
        reason: reason.value,
      );

  return await useCase.execute();
}
