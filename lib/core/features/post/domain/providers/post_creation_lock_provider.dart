import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_creation_lock_provider.g.dart';

/// Provider to track ongoing post creation requests per user to prevent duplicates
@Riverpod(keepAlive: true)
class PostCreationLock extends _$PostCreationLock {
  @override
  Set<String> build() {
    return {};
  }

  bool isLocked(String userId) {
    return state.contains(userId);
  }

  void lock(String userId) {
    state = {...state, userId};
  }

  void unlock(String userId) {
    state = state.where((id) => id != userId).toSet();
  }
}
