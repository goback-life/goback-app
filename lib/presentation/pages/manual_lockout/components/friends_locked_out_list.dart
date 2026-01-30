import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/get_friends_locked_out_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/friend_locked_out_item.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FriendsLockedOutList extends HookConsumerWidget {
  const FriendsLockedOutList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final friendsAsync = ref.watch(getFriendsLockedOutProvider);

    return friendsAsync.when(
      data: (result) => result.fold(
        (friends) {
          if (friends.isEmpty) return const SizedBox.shrink();
          return _buildList(context, ref, friends, colorScheme, textTheme);
        },
        (_) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<LockoutSessionModel> friends,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            translator.translate('pages.manual_lockout.friends_locked_out.title'),
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.surface.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final session = friends[index];
              return FriendLockedOutItem(
                session: session,
                onTap: () => _handleJoinTap(context, ref, session),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoinTap(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    final shouldJoin = await JoinLockoutDialog.show(context, session);
    if (shouldJoin != true || !context.mounted) return;

    try {
      final notifier = ref.read(manualLockoutNotifierProvider.notifier);
      await notifier.joinLockout(session.id);
      // Lockout state already updated, view will reflect changes
    } catch (e) {
      logger.error('Error joining lockout', exception: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translator.translate('pages.manual_lockout.friends_locked_out.error'),
            ),
          ),
        );
      }
    }
  }
}
