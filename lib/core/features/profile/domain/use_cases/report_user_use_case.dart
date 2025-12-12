import 'package:cloudless/core/features/profile/data/mappers/user_report_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/profile/data/services/user_report_service.dart';
import 'package:cloudless/core/features/profile/domain/exceptions/user_report_exception.dart';
import 'package:cloudless/core/features/profile/domain/models/user_report_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class ReportUserUseCase implements UseCaseContract<Result<UserReportModel>> {
  ReportUserUseCase({required this.service});

  final UserReportService service;

  String? _reportedUserId;
  String? _reportedBy;
  String? _reason;

  ReportUserUseCase withReportData({
    required String reportedUserId,
    required String reportedBy,
    required String reason,
  }) {
    return ReportUserUseCase(service: service)
      .._reportedUserId = reportedUserId
      .._reportedBy = reportedBy
      .._reason = reason;
  }

  @override
  Future<Result<UserReportModel>> execute() async {
    final reportedUserId = _reportedUserId;
    final reportedBy = _reportedBy;
    final reason = _reason;

    if (reportedUserId == null || reportedUserId.isEmpty) {
      logger.info('Reported user ID is required for reporting');
      return Result.failure(
        const UserReportException('Reported user ID is required'),
      );
    }

    if (reportedBy == null || reportedBy.isEmpty) {
      logger.info('Reporter user ID is required for reporting');
      return Result.failure(
        const UserReportException('Reporter user ID is required'),
      );
    }

    if (reason == null || reason.isEmpty) {
      logger.info('Reason is required for reporting');
      return Result.failure(
        const UserReportException('Reason is required for reporting'),
      );
    }

    try {
      // Check if report already exists
      final hasReported = await service.hasUserReportedUser(
        reportedUserId: reportedUserId,
        reportedBy: reportedBy,
      );

      if (hasReported) {
        return Result.failure(
          const UserReportException(
            'User already reported',
            'REPORT_ALREADY_EXISTS',
          ),
        );
      }

      // Create the report
      final dto = await service.createReport(
        reportedUserId: reportedUserId,
        reportedBy: reportedBy,
        reason: reason,
      );

      final model = UserReportDtoToModelMapper().mapDto(dto);
      return Result.success(model);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to report user',
        exception: e,
        stackTrace: stackTrace,
      );
      return Result.failure(UserReportException(e.toString()));
    }
  }
}
