import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'post_action_event.freezed.dart';

/// Represents an action performed on a post.
@freezed
sealed class PostActionEvent with _$PostActionEvent {
  const PostActionEvent._();

  const factory PostActionEvent({
    required PostActionType action,
    required DateTime timestamp,
    String? postId, // Post ID for create actions to enable immediate feed insertion
  }) = _PostActionEvent;
}
