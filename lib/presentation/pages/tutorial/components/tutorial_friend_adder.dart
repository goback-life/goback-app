import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_invite_tab.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_search_tab.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Friend-adding panel for the tutorial lockout phase.
///
/// Two tabs (Invite user, Existing user) with a progress
/// indicator showing friend requests sent out of 4.
class TutorialFriendAdder extends HookConsumerWidget {
  const TutorialFriendAdder({
    super.key,
    required this.friendsAdded,
    required this.onFriendAdded,
  });

  final int friendsAdded;
  final VoidCallback onFriendAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0 = Invite user, 1 = Existing user

    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: 24,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            _ProgressRow(friendsAdded: friendsAdded),
            const SizedBox(height: 16),
            // Tab switcher
            _TabSwitcher(
              selectedTab: selectedTab.value,
              onTabChanged: (i) => selectedTab.value = i,
            ),
            const SizedBox(height: 16),
            // Tab content
            Expanded(
              child: selectedTab.value == 0
                  ? TutorialInviteTab(onFriendAdded: onFriendAdded)
                  : TutorialSearchTab(onFriendAdded: onFriendAdded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.friendsAdded});

  final int friendsAdded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$friendsAdded of 4 requests sent',
          style: const TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MainColors.dark,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < friendsAdded;
            return Container(
              width: TutorialLayout.progressDotSize,
              height: TutorialLayout.progressDotSize,
              margin: EdgeInsets.symmetric(
                horizontal: TutorialLayout.progressDotSpacing / 2,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? MainColors.accent : MainColors.grey300,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: 'Invite user',
          isSelected: selectedTab == 0,
          onTap: () => onTabChanged(0),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Existing user',
          isSelected: selectedTab == 1,
          onTap: () => onTabChanged(1),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? MainColors.accent.withValues(alpha: 0.3)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? MainColors.accent
                  : MainColors.grey300.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? MainColors.accent : MainColors.grey500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
