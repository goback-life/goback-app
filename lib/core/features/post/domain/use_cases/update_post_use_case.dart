import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class UpdatePostUseCase implements UseCaseContract<Result<PostModel>> {
  UpdatePostUseCase({required this.repository});

  final PostRepositoryContract repository;

  PostDataModel? _postData;

  UpdatePostUseCase withPostData(PostDataModel postData) {
    return UpdatePostUseCase(repository: repository).._postData = postData;
  }

  @override
  Future<Result<PostModel>> execute() async {
    final postData = _postData;

    if (postData == null) {
      logger.info('Post data is required');
      return Result.failure(Exception('Post data is required'));
    }

    if (postData.postId == null) {
      logger.info('Post ID is required for update');
      return Result.failure(Exception('Post ID is required for update'));
    }

    return await repository.updatePost(postData);
  }
}
