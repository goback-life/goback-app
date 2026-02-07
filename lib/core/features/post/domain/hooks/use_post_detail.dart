import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_by_id_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

typedef PostDetailResult = ({
  FeedPostModel? post,
  bool isLoading,
  String? errorMessage,
});

/// Hook for loading post detail with cache-then-network strategy.
/// Shows fallback immediately, then fetches fresh data to show edits.
PostDetailResult usePostDetail({
  required WidgetRef ref,
  required String postId,
  FeedPostModel? fallbackPost,
}) {
  final post = useState<FeedPostModel?>(fallbackPost);
  final isLoading = useState<bool>(fallbackPost == null);
  final errorMessage = useState<String?>(null);

  useEffect(() {
    // Show fallback immediately for instant UI
    if (fallbackPost != null && fallbackPost.id == postId) {
      post.value = fallbackPost;
    }

    // Always fetch fresh data from server (shows edits like description changes)
    Future<void> loadPost() async {
      final result = await ref.read(getPostByIdProvider(postId: postId).future);

      result.fold(
        (feedPost) {
          post.value = feedPost;
          isLoading.value = false;
        },
        (error) {
          logger.error('Failed to load post: $postId', exception: error);
          // Keep fallback if fetch fails
          if (post.value == null) {
            errorMessage.value = 'Impossibile caricare il post';
          }
          isLoading.value = false;
        },
      );
    }

    loadPost();

    return null;
  }, [postId]);

  return (
    post: post.value,
    isLoading: isLoading.value,
    errorMessage: errorMessage.value,
  );
}
