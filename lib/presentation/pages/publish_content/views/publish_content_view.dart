import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_member_exclusion.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_empty_state.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_member/main_members_list.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/publish_content/components/publish_content_button.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_presentation/widgets/layout/bottomed_list_view.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
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

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: BottomedListView(
            useSafeArea: true,
            bottom: Padding(
              padding: EdgeInsets.only(bottom: bottomMargin),
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

                        final result = await contentCreation
                            .publishPostWithExclusions(excludedUsersList);

                        isProcessing.value = false;

                        if (result != null && context.mounted) {
                          result.fold(
                            (post) {
                              final successKey = postCreationData.isEditing
                                  ? 'pages.publish_content.snackbar.update_success_message'
                                  : 'pages.publish_content.snackbar.success_message';

                              MainSnackbar.showSuccess(
                                context,
                                translator.translate(successKey),
                              );

                              if (context.mounted) {
                                router.go(const HomeRoutable());
                              }
                            },
                            (error) {
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
                            },
                          );
                        }
                      }
                    : null,
              ),
            ),
            children: [
              Column(
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
                    parentPostAuthorId: memberExclusionData.parentPostAuthorId,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
