import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_post_replies_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<FeedPostModel>>> getPostReplies(
  Ref ref, {
  required String postId,
}) async {
  final repository = ref.watch(postRepositoryProvider);
  return await repository.getPostReplies(postId: postId);
}

