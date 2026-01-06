import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class CreatePostUseCase implements UseCaseContract<Result<PostModel>> {
  CreatePostUseCase({required this.repository});

  final PostRepositoryContract repository;

  PostDataModel? _postData;

  CreatePostUseCase withPostData(PostDataModel postData) {
    return CreatePostUseCase(repository: repository).._postData = postData;
  }

  @override
  Future<Result<PostModel>> execute() async {
    final postData = _postData;

    if (postData == null) {
      logger.info('Post data is required');
    }

    // For text posts, media files are not required
    if (postData!.contentType != ContentType.text &&
        postData.mediaFiles.isEmpty) {
      logger.info('Media files are required');
    }

    final validationResult = _validateMediaFiles(postData);

    return validationResult.fold(
      (value) async => await repository.createPost(postData),
      (error) async => Result.failure(error),
    );
  }

  Result<void> _validateMediaFiles(PostDataModel postData) {
    switch (postData.contentType) {
      case ContentType.image:
      case ContentType.audio:
      case ContentType.video:
        if (postData.mediaFiles.length != 1) {
          logger.info(
            'Single media file required for ${postData.contentType.name}',
          );
        }
        break;
      case ContentType.doubleImage:
        if (postData.mediaFiles.length != 2) {
          logger.info('Two image files required for double image post');
        }
        break;
      case ContentType.text:
        // Text posts don't require media files
        // Validation for text content (description length) is handled in PostCreationDto
        if (postData.mediaFiles.isNotEmpty) {
          logger.info('Text posts should not have media files');
        }
        break;
    }

    return Result.success(null);
  }
}
