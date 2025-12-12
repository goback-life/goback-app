import 'package:cloudless/core/features/post/data/mappers/feed_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/feed_response_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/providers/post_service_provider.dart';
import 'package:cloudless/core/features/post/data/repositories/post_repository.dart';
import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repository_provider.g.dart';

@Riverpod(keepAlive: false)
PostRepositoryContract postRepository(Ref ref) {
  return PostRepository(
    postService: ref.watch(postServiceProvider),
    postMapper: PostDtoToModelMapper(),
    feedResponseMapper: FeedResponseDtoToModelMapper(
      feedPostMapper: FeedPostDtoToModelMapper(),
    ),
    feedPostMapper: FeedPostDtoToModelMapper(),
  );
}
