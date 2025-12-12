import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailReportReasonButton extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReportReasonButton({
    required this.reason,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    super.key,
  });

  final PostReportReason reason;
  final String label;
  final void Function(PostReportReason reason) onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (isSecondary) {
      return CallToAction.primary.outlined(
        action: () => onPressed(reason),
        label: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            height: 20.0 / 14.0,
            color: colorScheme.surfaceContainerLow,
          ),
        ),
        horizontalMargin: modalHorizontalMargin,
        height: modalButtonHeight,
      );
    }

    return CallToAction.danger.outlined(
      action: () => onPressed(reason),
      label: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          height: 20.0 / 14.0,
          color: colorScheme.error,
        ),
      ),
      horizontalMargin: modalHorizontalMargin,
      height: modalButtonHeight,
    );
  }
}
