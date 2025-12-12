import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class DeleteReactionUseCase implements UseCaseContract<Result<void>> {
  DeleteReactionUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _reactionId;

  DeleteReactionUseCase withReactionData({required String reactionId}) {
    return DeleteReactionUseCase(repository: repository)
      .._reactionId = reactionId;
  }

  @override
  Future<Result<void>> execute() async {
    final reactionId = _reactionId;

    if (reactionId == null || reactionId.isEmpty) {
      logger.info('Reaction ID is required for deleting reaction');
      return Result.failure(Exception('Reaction ID is required'));
    }

    return await repository.deleteReaction(reactionId: reactionId);
  }
}
