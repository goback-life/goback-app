import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_report_reason_button.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PostDetailReportReasonModal extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReportReasonModal({
    required this.onReasonSelected,
    super.key,
  });

  final void Function(PostReportReason reason) onReasonSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(modalBorderRadius),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: modalHorizontalPadding),
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: modalBorderRadius,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: modalVerticalPadding,
            horizontal: modalHorizontalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                translator.translate('components.post_report_modal.title'),
                style: textTheme.titleLarge?.copyWith(height: 26.0 / 20.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: modalTitleToDescription),
              Text(
                translator.translate('components.post_report_modal.subtitle'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outlineVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: modalDescriptionToActions),
              PostDetailReportReasonButton(
                reason: PostReportReason.nudity,
                label: translator.translate(
                  'components.post_report_modal.reasons.nudity',
                ),
                onPressed: onReasonSelected,
              ),
              SizedBox(height: modalActionSpacing),
              PostDetailReportReasonButton(
                reason: PostReportReason.shockingContent,
                label: translator.translate(
                  'components.post_report_modal.reasons.shocking_content',
                ),
                onPressed: onReasonSelected,
              ),
              SizedBox(height: modalActionSpacing),
              PostDetailReportReasonButton(
                reason: PostReportReason.hateSpeech,
                label: translator.translate(
                  'components.post_report_modal.reasons.hate_speech',
                ),
                onPressed: onReasonSelected,
              ),
              SizedBox(height: modalActionSpacing),
              PostDetailReportReasonButton(
                reason: PostReportReason.bullying,
                label: translator.translate(
                  'components.post_report_modal.reasons.bullying',
                ),
                onPressed: onReasonSelected,
              ),
              SizedBox(height: modalActionSpacing),
              PostDetailReportReasonButton(
                reason: PostReportReason.spam,
                label: translator.translate(
                  'components.post_report_modal.reasons.spam',
                ),
                onPressed: onReasonSelected,
              ),
              SizedBox(height: modalActionSpacing),
              PostDetailReportReasonButton(
                reason: PostReportReason.changedMind,
                label: translator.translate(
                  'components.post_report_modal.reasons.changed_mind',
                ),
                isSecondary: true,
                onPressed: onReasonSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
