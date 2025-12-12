import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_by_id_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

typedef PostDetailResult = ({
  FeedPostModel? post,
  bool isLoading,
  String? errorMessage,
});

PostDetailResult usePostDetail({
  required WidgetRef ref,
  required String postId,
  FeedPostModel? fallbackPost,
}) {
  final post = useState<FeedPostModel?>(null);
  final isLoading = useState<bool>(true);
  final errorMessage = useState<String?>(null);

  useEffect(() {
    // If we have a fallback post with matching ID, use it immediately
    if (fallbackPost != null && fallbackPost.id == postId) {
      post.value = fallbackPost;
      isLoading.value = false;
      errorMessage.value = null;
      return null;
    }

    // Otherwise, load the post from the backend
    isLoading.value = true;
    errorMessage.value = null;

    Future<void> loadPost() async {
      final result = await ref.read(getPostByIdProvider(postId: postId).future);

      result.fold(
        (feedPost) {
          post.value = feedPost;
          isLoading.value = false;
        },
        (error) {
          logger.error('Failed to load post: $postId', exception: error);
          post.value = null;
          isLoading.value = false;
          errorMessage.value = 'Impossibile caricare il post';
        },
      );
    }

    loadPost();

    return null;
  }, [postId, fallbackPost]);

  return (
    post: post.value,
    isLoading: isLoading.value,
    errorMessage: errorMessage.value,
  );
}
