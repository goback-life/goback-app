import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_block_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_remove_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Menu for profile actions like report, block, and remove.
class ProfileActionsMenu extends HookConsumerWidget
    with MainLayout, ProfileActionsLayout {
  const ProfileActionsMenu({
    required this.userId,
    required this.onActionCompleted,
    this.showRemoveOption = false,
    this.showBlockOption = true,
    this.onRemoveTap,
    super.key,
  });

  final String userId;
  final bool showRemoveOption;
  final bool showBlockOption;
  final VoidCallback onActionCompleted;
  final VoidCallback? onRemoveTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.clear,
        tint: MainColors.accent,
        cornerRadius: menuBorderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: menuVerticalSpacing),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRemoveOption && onRemoveTap != null) ...[
                ProfileRemoveAction(onTap: onRemoveTap!),
                Container(
                  height: menuDividerHeight,
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
              ],
              if (showBlockOption) ...[
                ProfileBlockAction(
                  blockedUserId: userId,
                  onActionCompleted: onActionCompleted,
                ),
                Container(
                  height: menuDividerHeight,
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
              ],
              ProfileReportAction(
                reportedUserId: userId,
                onActionCompleted: onActionCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
