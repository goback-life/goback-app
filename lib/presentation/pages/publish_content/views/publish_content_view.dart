import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_member_exclusion.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_empty_state.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_member/main_members_list.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/share/domain/providers/pending_share_provider.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/publish_content/components/publish_content_button.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PublishContentView extends HookConsumerWidget
    with MainLayout, PublishContentLayout {
  const PublishContentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentCreation = usePostCreation(ref);
    final memberExclusionData = useMemberExclusion(ref);
    final asyncValue = ref.watch(getCircleMembersProvider);
    final postCreationData = ref.watch(postCreationNotifierProvider);
    final parentPost = ref.watch(parentPostReferenceNotifierProvider);

    final isProcessing = useState<bool>(false);

    useLoadingOverlay(isProcessing, context: context);

    return MainDataLoader(
      provider: asyncValue,
      useScaffold: false,
      onRetry: () {
        ref.invalidate(getCircleMembersProvider);
      },
      builder: (context, members) {
        if (members.isEmpty) {
          return const MainEmptyState();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          memberExclusionData.initializeWith(
            members,
            taggedUsers: contentCreation.data.taggedUserIds,
            excludedUsers: contentCreation.data.excludedUserIds,
            parentPostAuthorId: parentPost?.authorId,
          );
        });

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (parentPost != null) ...[
                      ParentPostPreview(parentPost: parentPost),
                      SizedBox(height: membersListSearchToList),
                    ],
                    MainSearchBar(
                      searchQuery: memberExclusionData.searchQuery,
                      onSearchChanged: memberExclusionData.updateSearchQuery,
                    ),
                    SizedBox(height: membersListSearchToList),
                    Row(
                      children: [
                        Expanded(
                          child: CallToAction.primary.filled(
                            action: memberExclusionData.selectAll,
                            label: Text(
                              translator.translate(
                                'pages.publish_content.select_all',
                              ),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            horizontalMargin: 0,
                            borderRadius: BorderRadius.circular(8),
                            height: 44,
                          ),
                        ),
                        SizedBox(width: horizontalPadding / 2),
                        Expanded(
                          child: CallToAction.primary.filled(
                            action: memberExclusionData.deselectAll,
                            label: Text(
                              translator.translate(
                                'pages.publish_content.deselect_all',
                              ),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            horizontalMargin: 0,
                            borderRadius: BorderRadius.circular(8),
                            height: 44,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: membersListSearchToList),
                    MainMembersList(
                      members: members,
                      groupedMembers: memberExclusionData.groupedMembers,
                      searchQuery: memberExclusionData.searchQuery,
                      onSearchChanged: memberExclusionData.updateSearchQuery,
                      action: MemberItemAction.selection,
                      selectedMembers: memberExclusionData.selectedMembers,
                      onMemberSelectionChanged:
                          memberExclusionData.updateSelectedMembers,
                      taggedUserIds: memberExclusionData.taggedUserIds,
                      parentPostAuthorId:
                          memberExclusionData.parentPostAuthorId,
                      onSelectOnly: memberExclusionData.selectOnly,
                    ),
                    SizedBox(height: bottomMargin + 80),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: bottomMargin,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: MainColors.dark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: PublishContentButton(
                  onTap: contentCreation.canPublish && !isProcessing.value
                      ? () async {
                          if (isProcessing.value) {
                            return;
                          }

                          isProcessing.value = true;

                          final excludedUsersList = memberExclusionData
                              .excludedMembers
                              .toList();

                          // Capture before publish — ref may be
                          // disposed by lockout cleanup inside hook.
                          final shareNotifier = ref.read(
                            pendingShareProvider.notifier,
                          );
                          final lockoutId = ref.read(
                            pendingLockoutPostProvider,
                          );
                          final userId = ref
                              .read(getCurrentUserProvider)
                              .whenOrNull(
                                data: (r) => r.fold((u) => u.id, (_) => null),
                              );
                          final imagePath =
                              contentCreation.data.firstFrame?.path ??
                              contentCreation.mainImage?.path;
                          final description = contentCreation.data.description;

                          final result = await contentCreation
                              .publishPostWithExclusions(excludedUsersList);

                          if (context.mounted) {
                            isProcessing.value = false;
                          }

                          if (result != null) {
                            final succeeded = result.fold(
                              (_) => true,
                              (_) => false,
                            );

                            if (succeeded) {
                              if (context.mounted) {
                                final successKey = postCreationData.isEditing
                                    ? 'pages.publish_content.snackbar.update_success_message'
                                    : 'pages.publish_content.snackbar.success_message';
                                MainSnackbar.showSuccess(
                                  context,
                                  translator.translate(successKey),
                                );
                              }

                              if (!postCreationData.isEditing &&
                                  lockoutId != null &&
                                  userId != null) {
                                shareNotifier.state = (
                                  lockoutId: lockoutId,
                                  authorId: userId,
                                  imagePath: imagePath,
                                  description: description,
                                );
                              }

                              router.go(const HomeRoutable());
                            } else if (context.mounted) {
                              final errorKey = postCreationData.isEditing
                                  ? 'components.alert.post_error.update_error_message'
                                  : 'components.alert.post_error.error_message';
                              MainAlert.showError(
                                context: context,
                                title: translator.translate(
                                  'components.alert.post_error.title',
                                ),
                                content: translator.translate(errorKey),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
