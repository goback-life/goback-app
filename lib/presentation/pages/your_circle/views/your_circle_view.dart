import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_connection_requests.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_remove_connection.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/search_users_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_empty_state.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/pages/your_circle/components/connection_request_tiles.dart';
import 'package:cloudless/presentation/pages/your_circle/components/leaderboard_tile.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_add_menu.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_remove_dialog.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_search_pill.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_storage/dedecube_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kMaxCircleSize = 150;
const _kFullAlertKey = 'circle_full_alert_shown';

class YourCircleView extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const YourCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleMembersData = useCircleMembers(ref);
    final removeConnection = useRemoveConnection(ref);
    final inviteState = useSmsSender(ref);
    final leaderboardAsync = ref.watch(getCircleLeaderboardProvider);
    final searchController = useTextEditingController();
    final externalSearch = useSearchUsers(ref);
    final requestsData = useConnectionRequests(ref);
    final mq = MediaQuery.of(context);
    final bottomPad = mq.padding.bottom;
    final topPad = mq.padding.top;
    final sidePad = mq.size.width * 0.04;

    final removeMode = useState(false);
    final selectedIds = useState(<String>{});
    final isFull = circleMembersData.allUsers.length >= _kMaxCircleSize;

    // One-time circle full alert.
    useEffect(() {
      if (!isFull) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final shown = await simpleStorage.getBool(_kFullAlertKey, false);
        if (shown) return;
        await simpleStorage.setBool(_kFullAlertKey, true);
        if (!context.mounted) return;
        _showCircleFullAlert(context);
      });
      return null;
    }, [isFull]);

    return MainDataLoader(
      provider: leaderboardAsync,
      useScaffold: false,
      onRetry: () {
        ref.invalidate(getCircleMembersProvider);
        ref.invalidate(getCircleLeaderboardProvider);
      },
      builder: (context, _) {
        // Get leaderboard entries from the provider
        final leaderboardEntries =
            leaderboardAsync.valueOrNull?.fold(
              (entries) => entries,
              (error) => <LeaderboardEntryDto>[],
            ) ??
            <LeaderboardEntryDto>[];

        // Pair entries with their real rank before filtering
        final ranked = leaderboardEntries
            .asMap()
            .entries
            .map((e) => (rank: e.key + 1, entry: e.value))
            .toList();

        // Apply search filter (preserves original ranks)
        final searchQuery = circleMembersData.searchQuery;
        final filtered = searchQuery.isEmpty
            ? ranked
            : ranked
                  .where(
                    (r) => r.entry.username.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        // External search results (only when actively searching)
        final externalResults = searchQuery.isNotEmpty
            ? externalSearch.results
            : <SearchUserResult>[];
        final totalItems = filtered.length + externalResults.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 0: Scrollable list (leaderboard + external results)
            if (totalItems == 0 && searchQuery.isEmpty)
              const Positioned.fill(child: Center(child: MainEmptyState()))
            else
              ListView.builder(
                reverse: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom:
                      (removeMode.value
                          ? removeButtonHeight
                          : searchPillHeight) +
                      bottomBarBottomPadding +
                      bottomPad +
                      24,
                  top: topPad + 16,
                ),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // Circle members first (bottom of reversed list),
                  // external users after (top when scrolling up).
                  if (index < filtered.length) {
                    final item = filtered[index];
                    return LeaderboardTile(
                      entry: item.entry,
                      rank: item.rank,
                      isRemoveMode: removeMode.value,
                      isSelected: selectedIds.value.contains(item.entry.userId),
                      onTap: () => router.push(
                        CircleProfileRoutable(userId: item.entry.userId),
                      ),
                      onSwipeDelete: item.entry.isCurrentUser
                          ? null
                          : () => _confirmRemove(
                              context,
                              item.entry.username,
                              item.entry.userId,
                              removeConnection,
                              ref,
                            ),
                      onToggle: () {
                        final ids = Set<String>.from(selectedIds.value);
                        if (ids.contains(item.entry.userId)) {
                          ids.remove(item.entry.userId);
                        } else {
                          ids.add(item.entry.userId);
                        }
                        selectedIds.value = ids;
                      },
                    );
                  }
                  // External search result — matches LeaderboardTile layout
                  final extIndex = index - filtered.length;
                  final (profile, status) = externalResults[extIndex];
                  return _ExternalUserTile(
                    profile: profile,
                    status: status,
                    isCircleFull: isFull,
                    onConnect: () {
                      requestsData.send(profile.id).then((result) {
                        result.fold((value) {
                          ref.invalidate(
                            searchUsersProvider(externalSearch.query),
                          );
                          ref.invalidate(getOutgoingRequestsProvider);
                          if (value == 'auto_accepted') {
                            ref.invalidate(getCircleMembersProvider);
                            ref.invalidate(getCircleLeaderboardProvider);
                          }
                        }, (_) {});
                      });
                    },
                  );
                },
              ),

            // Layer 1: Fixed bottom bar
            Positioned(
              left: sidePad,
              right: sidePad,
              bottom: bottomPad + bottomBarBottomPadding,
              child: removeMode.value
                  ? _RemoveBar(
                      selectedCount: selectedIds.value.length,
                      onRemove: () => _batchRemove(
                        context,
                        selectedIds,
                        removeMode,
                        removeConnection,
                        ref,
                      ),
                      onCancel: () {
                        removeMode.value = false;
                        selectedIds.value = {};
                      },
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        YourCircleSearchPill(
                          searchQuery: circleMembersData.searchQuery,
                          onSearchChanged: (query) {
                            circleMembersData.updateSearchQuery(query);
                            externalSearch.updateQuery(query);
                          },
                          controller: searchController,
                        ),
                        const Spacer(),
                        if (isFull)
                          SizedBox(
                            height: searchPillHeight,
                            child: Center(
                              child: _MinusPill(
                                onTap: () {
                                  removeMode.value = true;
                                  selectedIds.value = {};
                                  circleMembersData.updateSearchQuery('');
                                  searchController.clear();
                                },
                              ),
                            ),
                          )
                        else
                          YourCircleAddMenu(
                            onShareInvite: inviteState.shareInvite,
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String username,
    String userId,
    RemoveConnectionCallback removeConnection,
    WidgetRef ref,
  ) async {
    final confirmed = await showRemoveFriendDialog(
      context: context,
      username: username,
    );
    if (!confirmed) return;

    await removeConnection(userId);
    ref.invalidate(getCircleMembersProvider);
    ref.invalidate(getCircleLeaderboardProvider);
  }

  Future<void> _batchRemove(
    BuildContext context,
    ValueNotifier<Set<String>> selectedIds,
    ValueNotifier<bool> removeMode,
    RemoveConnectionCallback removeConnection,
    WidgetRef ref,
  ) async {
    final count = selectedIds.value.length;
    final confirmed = await showRemoveFriendDialog(
      context: context,
      username: '$count connection${count > 1 ? 's' : ''}',
    );
    if (!confirmed) return;

    HapticFeedback.mediumImpact();
    for (final id in selectedIds.value) {
      await removeConnection(id);
    }
    selectedIds.value = {};
    removeMode.value = false;
    ref.invalidate(getCircleMembersProvider);
    ref.invalidate(getCircleLeaderboardProvider);
  }

  Future<void> _showCircleFullAlert(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            child: AppGlassContainer(
              config: const GlassConfig(
                tint: MainColors.accent,
                cornerRadius: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your circle is full!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: MainColors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'ve reached the maximum of '
                        '$_kMaxCircleSize connections.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: MainColors.dark.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: SizedBox(
                          width: 120,
                          height: 44,
                          child: AppGlassContainer(
                            config: const GlassConfig(
                              tint: MainColors.accent,
                              cornerRadius: 22,
                            ),
                            child: const Center(
                              child: Text(
                                'Got it',
                                style: TextStyle(
                                  fontFamily: MainFontFamilies.quicksand,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: MainColors.dark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minus pill — replaces plus button when circle is at capacity
// ---------------------------------------------------------------------------

class _MinusPill extends StatelessWidget with MainLayout, YourCircleLayout {
  const _MinusPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: addButtonSize,
        height: 16,
        child: AppGlassContainer(
          config: const GlassConfig(
            variant: GlassVariant.clear,
            tint: MainColors.accent,
            cornerRadius: 8,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remove bar — bottom bar in remove mode
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// External user tile — matches LeaderboardTile layout with a Connect button
// ---------------------------------------------------------------------------

class _ExternalUserTile extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const _ExternalUserTile({
    required this.profile,
    required this.status,
    required this.isCircleFull,
    required this.onConnect,
  });

  final ProfileModel profile;
  final ConnectionStatus status;
  final bool isCircleFull;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final sidePad = MediaQuery.of(context).size.width * 0.04;
    final disabledColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.3);

    String label;
    Color color;
    VoidCallback? onTap;
    switch (status) {
      case ConnectionStatus.none:
        label = isCircleFull ? 'Full' : 'Connect';
        color = isCircleFull ? disabledColor : MainColors.accent;
        onTap = isCircleFull ? null : onConnect;
      case ConnectionStatus.pendingOutgoing:
        label = 'Pending';
        color = disabledColor;
        onTap = null;
      case ConnectionStatus.pendingIncoming:
        label = isCircleFull ? 'Full' : 'Accept';
        color = isCircleFull ? disabledColor : MainColors.accent;
        onTap = isCircleFull ? null : onConnect;
      case ConnectionStatus.connected:
        label = 'Connected';
        color = disabledColor;
        onTap = null;
    }

    return SizedBox(
      height: friendTileHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: sidePad),
          // Blank rank area (matches LeaderboardTile rank column)
          SizedBox(width: rankWidth),
          SizedBox(width: rankRightMargin),
          // Avatar — same size as leaderboard friend avatar
          _buildAvatar(context),
          SizedBox(width: friendAvatarToText),
          // Username
          Expanded(
            child: Text(
              profile.username,
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: friendTextSize,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: friendLetterSpacing,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Action button (where duration/stats would be)
          Padding(
            padding: EdgeInsets.only(right: sidePad),
            child: SmallActionButton(label: label, color: color, onTap: onTap),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final hasAvatar =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    return Container(
      width: friendAvatarSize,
      height: friendAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MainColors.accent.withValues(alpha: hasAvatar ? 0.0 : 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(
              profile.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  profile.username.isNotEmpty
                      ? profile.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: friendAvatarSize * 0.4,
                    color: MainColors.dark,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                profile.username.isNotEmpty
                    ? profile.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w500,
                  fontSize: friendAvatarSize * 0.4,
                  color: MainColors.dark,
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remove bar — bottom bar in remove mode
// ---------------------------------------------------------------------------

class _RemoveBar extends StatelessWidget with MainLayout, YourCircleLayout {
  const _RemoveBar({
    required this.selectedCount,
    required this.onRemove,
    required this.onCancel,
  });

  final int selectedCount;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canRemove = selectedCount > 0;
    return Center(
      child: GestureDetector(
        onTap: canRemove ? onRemove : onCancel,
        child: AnimatedOpacity(
          opacity: canRemove ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: removeButtonWidth,
            height: removeButtonHeight,
            child: AppGlassContainer(
              config: const GlassConfig(
                tint: MainColors.accent,
                cornerRadius: 47,
              ),
              child: const Center(
                child: Text(
                  'Remove connections',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w600,
                    fontSize: 27,
                    color: MainColors.dark,
                    letterSpacing: -1.62,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
