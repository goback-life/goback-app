import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/main_member/main_member_layout.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

enum MemberItemAction { none, navigation, selection, reaction }

class MainMemberItem extends StatelessWidget with MainLayout, MainMemberLayout {
  const MainMemberItem({
    required this.member,
    required this.action,
    this.isSelected,
    this.onSelectionChanged,
    this.onTap,
    this.isDisabled = false,
    this.reactionEmoji,
    this.onSelectOnly,
    super.key,
  });

  final ProfileModel member;
  final MemberItemAction action;
  final bool? isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onTap;
  final bool isDisabled;
  final String? reactionEmoji;
  final void Function(String memberId)? onSelectOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () {
        if (isDisabled && action == MemberItemAction.selection) {
          return;
        }

        switch (action) {
          case MemberItemAction.navigation:
            router.push(CircleProfileRoutable(userId: member.id));
            break;
          case MemberItemAction.selection:
            if (onSelectionChanged != null && isSelected != null) {
              onSelectionChanged!(!isSelected!);
            }
            break;
          case MemberItemAction.reaction:
            onTap?.call();
            break;
          case MemberItemAction.none:
            onTap?.call();
            break;
        }
      },
      onLongPress:
          action == MemberItemAction.selection &&
              onSelectOnly != null &&
              !isDisabled
          ? () {
              onSelectOnly!(member.id);
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: memberItemVerticalPadding),
        child: Row(
          children: [
            Opacity(
              opacity: isDisabled && action == MemberItemAction.selection
                  ? 0.3
                  : 1.0,
              child: ProfileImage(
                imageUrl: member.avatarUrl,
                username: member.username,
                size: memberItemImageSize,
                isEditable: false,
                showFromProfile: false,
                showFullScreen: false,
                showLoading: false,
              ),
            ),
            SizedBox(width: memberItemImageToText),
            Expanded(
              child: Text(
                member.username,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDisabled && action == MemberItemAction.selection
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : null,
                ),
              ),
            ),
            _buildTrailingWidget(colorScheme, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(ColorScheme colorScheme, BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    switch (action) {
      case MemberItemAction.navigation:
        return Assets.svg.next.render(
          colorFilter: colorScheme.onSurface.asSrcIn,
        );
      case MemberItemAction.selection:
        final isChecked = isSelected == true;
        final containerColor = isDisabled
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : (isChecked ? colorScheme.primaryContainer : Colors.transparent);
        final borderColor = isDisabled
            ? colorScheme.primary
            : (isChecked ? Colors.transparent : colorScheme.primaryContainer);

        return Container(
          width: memberItemIconSize,
          height: memberItemIconSize,
          padding: EdgeInsets.all(memberItemBorderRadius),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            color: containerColor,
          ),
          child: isChecked
              ? Assets.svg.check.render(
                  colorFilter: isDisabled ? colorScheme.primary.asSrcIn : null,
                )
              : null,
        );
      case MemberItemAction.reaction:
        return Text(reactionEmoji ?? '', style: textTheme.headlineSmall);
      case MemberItemAction.none:
        return const SizedBox.shrink();
    }
  }
}
