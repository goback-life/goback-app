import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Helper class for handling navigation in post detail view.
class PostDetailNavigation with MainLayout {
  /// Navigates to the user's profile based on whether they're the current user or connected.
  static Future<void> navigateToUserProfile(
    WidgetRef ref,
    String userId,
    String username,
  ) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final isCurrentUser =
        currentUserAsync.whenOrNull(
          data: (userResult) =>
              userResult.fold((user) => user.id == userId, (error) => false),
        ) ??
        false;

    if (isCurrentUser) {
      router.push(const ProfileRoutable());
    } else {
      final connectionResult = await ref.read(
        isUserConnectedProvider(userId).future,
      );
      final isConnected = connectionResult.fold((isConnected) => isConnected, (
        error,
      ) {
        logger.error('Failed to check user connection', exception: error);
        return false;
      });

      if (isConnected) {
        router.push(CircleProfileRoutable(userId: userId));
      } else {
        router.push(ExternalProfileRoutable(userId: userId));
      }
    }
  }
}
