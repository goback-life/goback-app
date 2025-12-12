import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_action_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_action_notifier_provider.g.dart';

/// Notifies when an action is performed on a post (create, update, delete, hide).
///
/// This provider is used to trigger feed updates when posts are modified.
@Riverpod(keepAlive: true)
class PostActionNotifier extends _$PostActionNotifier {
  @override
  PostActionEvent? build() => null;

  /// Notifies that a post was created.
  void notifyPostCreated() {
    state = PostActionEvent(
      action: PostActionType.create,
      timestamp: DateTime.now(),
    );
  }

  /// Notifies that a post was updated.
  void notifyPostUpdated() {
    state = PostActionEvent(
      action: PostActionType.update,
      timestamp: DateTime.now(),
    );
  }

  /// Notifies that a post was deleted.
  void notifyPostDeleted() {
    state = PostActionEvent(
      action: PostActionType.delete,
      timestamp: DateTime.now(),
    );
  }

  /// Notifies that a post was hidden.
  void notifyPostHidden() {
    state = PostActionEvent(
      action: PostActionType.hide,
      timestamp: DateTime.now(),
    );
  }

  /// Notifies that a post was reported.
  void notifyPostReported() {
    state = PostActionEvent(
      action: PostActionType.report,
      timestamp: DateTime.now(),
    );
  }

  /// Clears the current action event.
  void clearAction() {
    state = null;
  }
}
