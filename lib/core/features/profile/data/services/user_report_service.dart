import 'package:cloudless/core/features/profile/data/dtos/user_report_dto.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing user reports.
class UserReportService {
  const UserReportService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Checks if a user has already reported a specific user.
  Future<bool> hasUserReportedUser({
    required String reportedUserId,
    required String reportedBy,
  }) async {
    try {
      final existingReports = await supabaseClient
          .from('user_reports')
          .select()
          .eq('reported_user_id', reportedUserId)
          .eq('reported_by', reportedBy);

      return existingReports.isNotEmpty;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to check existing user report',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates a new report for a user.
  Future<UserReportDto> createReport({
    required String reportedUserId,
    required String reportedBy,
    required String reason,
  }) async {
    try {
      final response = await supabaseClient
          .from('user_reports')
          .insert({
            'reported_user_id': reportedUserId,
            'reported_by': reportedBy,
            'reason': reason,
          })
          .select()
          .single();

      return UserReportDto.fromJson(response);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create user report',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
