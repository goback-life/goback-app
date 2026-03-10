import 'package:cloudless/core/features/auth/domain/providers/sign_out_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/push_notification_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class LogoutButton extends HookConsumerWidget with MainLayout, SettingsLayout {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isLoading = useState(false);

    useLoadingOverlay(isLoading);

    Future<void> handleLogout() async {
      try {
        isLoading.value = true;

        final calendarCacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
        final feedCacheNotifier = ref.read(feedPostsCacheProvider.notifier);

        final result = await ref.read(signOutProvider.future);

        result.fold(
          (success) {
            ref.read(pushNotificationProvider).unregister();
            calendarCacheNotifier.clearCache();
            feedCacheNotifier.invalidateCache();
            if (context.mounted) {
              ref.invalidate(getProfileProvider);
            }
            router.go(const SignInRoutable());
          },
          (error) {
            if (context.mounted) {
              MainAlert.showError(
                context: context,
                title: translator.translate(
                  'components.alert.logout_error.title',
                ),
                content: translator.translate(
                  'components.alert.logout_error.content',
                ),
              );
            }
          },
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return CallToAction.primary.filled(
      action: isLoading.value ? null : handleLogout,
      label: Text(
        translator.translate('pages.settings.logout'),
        style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
      ),
    );
  }
}
