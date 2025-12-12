import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/post_report_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class ReportPostUseCase implements UseCaseContract<Result<PostReportModel>> {
  ReportPostUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _postId;
  String? _userId;
  String? _reason;

  ReportPostUseCase withReportData({
    required String postId,
    required String userId,
    required String reason,
  }) {
    return ReportPostUseCase(repository: repository)
      .._postId = postId
      .._userId = userId
      .._reason = reason;
  }

  @override
  Future<Result<PostReportModel>> execute() async {
    final postId = _postId;
    final userId = _userId;
    final reason = _reason;

    if (postId == null || postId.isEmpty) {
      logger.info('Post ID is required for reporting');
      return Result.failure(Exception('Post ID is required for reporting'));
    }

    if (userId == null || userId.isEmpty) {
      logger.info('User ID is required for reporting');
      return Result.failure(Exception('User ID is required for reporting'));
    }

    if (reason == null || reason.isEmpty) {
      logger.info('Reason is required for reporting');
      return Result.failure(Exception('Reason is required for reporting'));
    }

    return await repository.reportPost(
      postId: postId,
      userId: userId,
      reason: reason,
    );
  }
}
