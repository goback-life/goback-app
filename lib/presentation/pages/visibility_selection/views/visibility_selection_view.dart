import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_member_exclusion.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_layout.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_friend_tile.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class VisibilitySelectionView extends HookConsumerWidget
    with MainLayout, VisibilitySelectionLayout {
  const VisibilitySelectionView({
    required this.members,
    super.key,
  });

  final List<ConnectionMemberModel> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberExclusion = useMemberExclusion(ref);
    final postCreationData = ref.watch(postCreationNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Initialize with existing exclusions from the post creation state
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        memberExclusion.initializeWith(
          members,
          excludedUsers: postCreationData.excludedUserIds,
        );
      });
      return null;
    }, [members]);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Top safe area + back row + title
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _BackRow(onBack: () => router.pop()),
                        const SizedBox(height: 8),
                        Text(
                          translator.translate(
                            'pages.content_editor.restrict_visibility.title',
                          ),
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                            color: colorScheme.onSurface,
                            letterSpacing: -1.68,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        MainSearchBar(
                          searchQuery: memberExclusion.searchQuery,
                          onSearchChanged: memberExclusion.updateSearchQuery,
                        ),
                        SizedBox(height: searchToList),
                        // Select all / Deselect all pills
                        _SelectionPills(
                          onSelectAll: memberExclusion.selectAll,
                          onDeselectAll: memberExclusion.deselectAll,
                          pillHeight: pillHeight,
                          pillRadius: pillRadius,
                          spacing: pillsSpacing,
                        ),
                        SizedBox(height: searchToList),
                      ],
                    ),
                  ),
                ),
              ),

              // Grouped member list
              ..._buildGroupedList(memberExclusion, colorScheme),
            ],
          ),
        ),

        // Fixed bottom "Done" button
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(bottomBarPadding),
            child: _DoneButton(
              onTap: () {
                ref
                    .read(postCreationNotifierProvider.notifier)
                    .updateExcludedUsers(
                      memberExclusion.excludedMembers.toList(),
                    );
                router.pop();
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    MemberExclusionResult memberExclusion,
    ColorScheme colorScheme,
  ) {
    final grouped = memberExclusion.groupedMembers;
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      // Letter header
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding + 4,
              top: 8,
              bottom: 4,
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );

      // Member tiles for this letter
      widgets.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final profile = entry.value[index];
              final isSelected =
                  memberExclusion.selectedMembers.contains(profile.id);

              return GestureDetector(
                onLongPress: () => memberExclusion.selectOnly(profile.id),
                child: YourCircleFriendTile(
                  profile: profile,
                  isRemoveMode: true,
                  isSelected: isSelected,
                  onTap: () {},
                  onSwipeDelete: () {},
                  onToggle: () => memberExclusion.toggleMemberSelection(
                    profile.id,
                    selected: !isSelected,
                  ),
                ),
              );
            },
            childCount: entry.value.length,
          ),
        ),
      );
    }

    // Bottom spacing for done button clearance
    widgets.add(const SliverToBoxAdapter(child: SizedBox(height: 80)));

    return widgets;
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _SelectionPills extends StatelessWidget {
  const _SelectionPills({
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.pillHeight,
    required this.pillRadius,
    required this.spacing,
  });

  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final double pillHeight;
  final double pillRadius;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassPill(
          label: translator.translate(
            'pages.content_editor.restrict_visibility.select_all',
          ),
          onTap: onSelectAll,
          height: pillHeight,
          radius: pillRadius,
        ),
        SizedBox(width: spacing),
        _GlassPill(
          label: translator.translate(
            'pages.content_editor.restrict_visibility.deselect_all',
          ),
          onTap: onDeselectAll,
          height: pillHeight,
          radius: pillRadius,
        ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.label,
    required this.onTap,
    required this.height,
    required this.radius,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppGlassContainer(
        config: GlassConfig(
          cornerRadius: radius,
          interactive: true,
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: MainColors.white,
              letterSpacing: -0.84,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AppGlassContainer(
          config: const GlassConfig(
            cornerRadius: 47,
            interactive: true,
            tint: MainColors.accent,
          ),
          child: Container(
            width: 231,
            height: 51,
            alignment: Alignment.center,
            child: Text(
              translator.translate(
                'pages.content_editor.restrict_visibility.done',
              ),
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 24,
                color: MainColors.dark,
                letterSpacing: -1.44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
