import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds lockout share data temporarily between post creation and home screen.
/// Set after successful post creation, consumed by FeedView to show share dialog.
final pendingShareProvider =
    StateProvider<
      ({
        String lockoutId,
        String authorId,
        String? imagePath,
        String? description,
      })?
    >((_) => null);
