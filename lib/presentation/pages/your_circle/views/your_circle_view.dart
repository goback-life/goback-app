import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_remove_connection.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_empty_state.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_add_menu.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_friend_tile.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_remove_dialog.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_search_pill.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class YourCircleView extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const YourCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleMembersData = useCircleMembers(ref);
    final removeConnection = useRemoveConnection(ref);
    final asyncValue = ref.watch(getCircleMembersProvider);
    final searchController = useTextEditingController();
    final mq = MediaQuery.of(context);
    final bottomPad = mq.padding.bottom;
    final topPad = mq.padding.top;
    final sidePad = mq.size.width * 0.10;

    return MainDataLoader(
      provider: asyncValue,
      useScaffold: false,
      onRetry: () => ref.invalidate(getCircleMembersProvider),
      builder: (context, _) {
        final members = _flatMembers(circleMembersData);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 0: Scrollable friend list
            if (members.isEmpty)
              const Center(child: MainEmptyState())
            else
              ListView.builder(
                reverse: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: searchPillHeight + bottomBarBottomPadding + bottomPad + 24,
                  top: topPad + 16,
                ),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final profile = members[index];
                  return YourCircleFriendTile(
                    profile: profile,
                    onTap: () => router.push(
                      CircleProfileRoutable(userId: profile.id),
                    ),
                    onSwipeDelete: () => _confirmRemove(
                      context,
                      profile.username,
                      profile.id,
                      removeConnection,
                      ref,
                    ),
                  );
                },
              ),

            // Layer 1: Fixed bottom bar
            Positioned(
              left: sidePad,
              right: sidePad,
              bottom: bottomPad + bottomBarBottomPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  YourCircleSearchPill(
                    searchQuery: circleMembersData.searchQuery,
                    onSearchChanged: circleMembersData.updateSearchQuery,
                    controller: searchController,
                  ),
                  const Spacer(),
                  const YourCircleAddMenu(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Flattens grouped members into a single sorted list.
  List<ProfileModel> _flatMembers(CircleMembersData data) {
    final flat = <ProfileModel>[];
    for (final profiles in data.groupedMembers.values) {
      flat.addAll(profiles);
    }
    return flat;
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
  }
}
