import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart';
import 'package:cloudless/presentation/pages/notifications/views/notifications_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class CircleHubPage extends HookConsumerWidget {
  const CircleHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState<int>(0);
    final topPad = MediaQuery.of(context).padding.top;

    return AppGlassLayer(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            IndexedStack(
              index: tabIndex.value,
              children: const [
                SafeArea(child: FriendsLockedOutView()),
                NotificationsView(),
              ],
            ),
            Positioned(
              top: topPad + 8,
              left: 0,
              right: 0,
              child: Center(
                child: _TabToggle(
                  selectedIndex: tabIndex.value,
                  onChanged: (i) => tabIndex.value = i,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.clear,
        tint: MainColors.accent,
        cornerRadius: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabPill(
              label: 'Lockouts',
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _TabPill(
              label: 'Notifications',
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MainColors.accent.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
