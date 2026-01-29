import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';
import 'package:cloudless/core/features/post/domain/use_cases/get_feed_posts_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_feed_posts_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<FeedResponseModel>> getFeedPosts(
  Ref ref, {
  required String userId,
  int pageSize = 15,
  DateTime? cursor,
}) async {
  final useCase = GetFeedPostsUseCase(
    repository: ref.watch(postRepositoryProvider),
  );

  final result = await useCase.execute(
    userId: userId,
    pageSize: pageSize,
    cursor: cursor,
  );

  return result;
}
