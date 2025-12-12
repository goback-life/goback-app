import 'package:cloudless/core/features/post/data/dtos/post_report_dto.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing post reports.
class PostReportService {
  const PostReportService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Checks if a user has already reported a specific post.
  Future<bool> hasUserReportedPost({
    required String postId,
    required String userId,
  }) async {
    try {
      final existingReports = await supabaseClient
          .from('post_reports')
          .select()
          .eq('post_id', postId)
          .eq('reported_by', userId);

      return existingReports.isNotEmpty;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to check existing report',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates a new report for a post.
  Future<PostReportDto> createReport({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    try {
      final response = await supabaseClient
          .from('post_reports')
          .insert({'post_id': postId, 'reported_by': userId, 'reason': reason})
          .select()
          .single();

      return PostReportDto.fromJson(response);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create post report',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
