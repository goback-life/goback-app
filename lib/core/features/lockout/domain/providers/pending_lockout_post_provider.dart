import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_lockout_post_provider.g.dart';

/// Holds the lockout session ID temporarily when navigating to content editor
/// after lockout ends. This allows linking the post to the lockout session.
@Riverpod(keepAlive: true)
class PendingLockoutPost extends _$PendingLockoutPost {
  @override
  String? build() => null;

  void setLockoutId(String lockoutId) => state = lockoutId;
  void clear() => state = null;
}
