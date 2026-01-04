import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/remove_connection_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_member/main_members_list.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/pages/review_circle/review_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ReviewCircleView extends HookConsumerWidget
    with MainLayout, ReviewCircleLayout {
  const ReviewCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final circleMembersData = useCircleMembers(ref);
    final asyncValue = ref.watch(getCircleMembersProvider);
    final selectedMembers = useState<Set<String>>({});
    final isRemoving = useState<bool>(false);

    useLoadingOverlay(isRemoving, context: context);

    Future<void> handleBulkRemove() async {
      if (selectedMembers.value.isEmpty || isRemoving.value) {
        return;
      }

      final count = selectedMembers.value.length;
      
      final shouldProceed = await MainAlert.showFull<bool>(
        context: context,
        title: translator.translate('pages.review_circle.confirmation_title'),
        content: Text(
          translator.translate(
            'pages.review_circle.confirmation_content',
            arguments: {'count': count.toString()},
          ),
        ),
        primaryButtonText: translator.translate(
          'pages.review_circle.confirmation_confirm',
        ),
        textButtonStyle: textTheme.bodyMedium,
        secondaryButtonText: translator.translate(
          'pages.review_circle.confirmation_cancel',
        ),
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      );

      if (shouldProceed != true) {
        return;
      }

      isRemoving.value = true;

      int successCount = 0;
      int failureCount = 0;

      for (final userId in selectedMembers.value) {
        try {
          final result = await ref.read(removeConnectionProvider(userId).future);
          result.fold(
            (success) {
              if (success) {
                successCount++;
              } else {
                failureCount++;
              }
            },
            (_) => failureCount++,
          );
        } catch (e) {
          failureCount++;
        }
      }

      isRemoving.value = false;

      ref.invalidate(getCircleMembersProvider);
      selectedMembers.value = {};

      if (failureCount == 0) {
        MainSnackbar.showSuccess(
          context,
          translator.translate(
            'pages.review_circle.success_message',
            arguments: {'count': successCount.toString()},
          ),
        );
        router.pop();
      } else if (successCount > 0) {
        MainAlert.showFull(
          context: context,
          title: translator.translate('pages.review_circle.partial_success_title'),
          content: Text(
            translator.translate(
              'pages.review_circle.partial_success_content',
              arguments: {
                'success': successCount.toString(),
                'failure': failureCount.toString(),
              },
            ),
          ),
          primaryButtonText: translator.translate('components.alert.confirm_button'),
          onPrimaryPressed: () => router.pop(),
        );
      } else {
        MainAlert.showError(
          context: context,
          title: translator.translate('components.alert.remove_error.title'),
          content: translator.translate(
            'components.alert.remove_error.content',
          ),
        );
        router.pop();
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: MainDataLoader(
        provider: asyncValue,
        useScaffold: false,
        onRetry: () {
          ref.invalidate(getCircleMembersProvider);
        },
        builder: (context, members) {
          if (members.isEmpty) {
            return Center(
              child: Text(
                translator.translate('components.searchbar.no_results'),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(vertical: viewVerticalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MainSearchBar(
                        searchQuery: circleMembersData.searchQuery,
                        onSearchChanged: circleMembersData.updateSearchQuery,
                      ),
                      SizedBox(height: membersListSearchToList),
                      MainMembersList(
                        members: members,
                        groupedMembers: circleMembersData.groupedMembers,
                        searchQuery: circleMembersData.searchQuery,
                        onSearchChanged: circleMembersData.updateSearchQuery,
                        action: MemberItemAction.selection,
                        selectedMembers: selectedMembers.value,
                        onMemberSelectionChanged: (updated) {
                          selectedMembers.value = updated;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: bottomButtonPadding,
                ),
                child: CallToAction.primary.filled(
                  action: selectedMembers.value.isNotEmpty && !isRemoving.value
                      ? handleBulkRemove
                      : null,
                  label: Text(
                    selectedMembers.value.isEmpty
                        ? translator.translate(
                            'pages.review_circle.remove_button_disabled',
                          )
                        : translator.translate('pages.review_circle.remove_button'),
                    style: textTheme.labelLarge?.copyWith(
                      color: selectedMembers.value.isEmpty
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

