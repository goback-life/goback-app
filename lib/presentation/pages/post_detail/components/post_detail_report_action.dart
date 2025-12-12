import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/data/exceptions/post_report_exception.dart';
import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/report_post_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_report_reason_modal.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Menu action for reporting a post.
class PostDetailReportAction extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReportAction({
    required this.post,
    required this.onActionCompleted,
    super.key,
  });

  final FeedPostModel post;
  final VoidCallback onActionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _handleReport(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: menuItemHorizontalPadding,
          vertical: menuItemVerticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: menuIconSize,
              height: menuIconSize,
              child: Assets.svg.alert.render(),
            ),
            SizedBox(width: menuIconSpacing),
            Text(
              translator.translate('components.post_actions_menu.report'),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReport(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (dialogContext) => PostDetailReportReasonModal(
        onReasonSelected: (reason) async {
          router.pop();

          final currentUserAsync = ref.read(getCurrentUserProvider);
          final userId = currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (error) => null),
          );

          if (userId == null) {
            if (context.mounted) {
              await MainAlert.showError(
                context: context,
                title: translator.translate(
                  'components.report_post.error_title',
                ),
                content: translator.translate(
                  'components.report_post.error_content',
                ),
              );
            }
            onActionCompleted();
            return;
          }

          if (reason == PostReportReason.changedMind) {
            onActionCompleted();
            return;
          }

          final result = await ref.read(
            reportPostProvider(
              postId: post.id,
              userId: userId,
              reason: reason,
            ).future,
          );

          result.fold(
            (_) {
              ref
                  .read(postActionNotifierProvider.notifier)
                  .notifyPostReported();
              onActionCompleted();

              if (context.mounted) {
                MainSnackbar.showSuccess(
                  context,
                  translator.translate(
                    'components.report_post.success_content',
                  ),
                );

                router.pop();
              }
            },
            (error) async {
              if (!context.mounted) {
                onActionCompleted();
                return;
              }

              if (error is PostReportException &&
                  error.code == 'REPORT_ALREADY_EXISTS') {
                await MainAlert.showError(
                  context: context,
                  title: translator.translate(
                    'components.report_post.already_reported_title',
                  ),
                  content: translator.translate(
                    'components.report_post.already_reported_content',
                  ),
                );
              } else {
                await MainAlert.showError(
                  context: context,
                  title: translator.translate(
                    'components.report_post.error_title',
                  ),
                  content: translator.translate(
                    'components.report_post.error_content',
                  ),
                );
              }

              onActionCompleted();
            },
          );
        },
      ),
    );
  }
}
