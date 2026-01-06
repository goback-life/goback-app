import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_button.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_post_description.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_post_tag_user_section.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_selected_media.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_text_post.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ContentEditorView extends HookConsumerWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorView({
    required this.contentCreation,
    required this.showImagePicker,
    required this.showVideoPicker,
    required this.showMediaPicker,
    required this.showThumbnailPicker,
    required this.allUsers,
    required this.formattedDate,
    this.parentPost,
    this.isExtractingThumbnail = false,
    super.key,
  });

  final PostCreationResult contentCreation;
  final AsyncCallback showImagePicker;
  final AsyncCallback showVideoPicker;
  final AsyncCallback showMediaPicker;
  final AsyncCallback? showThumbnailPicker;
  final List<ProfileModel> allUsers;
  final String formattedDate;
  final ParentPostReferenceModel? parentPost;
  final bool isExtractingThumbnail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    final scrollController = useScrollController();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomSpace.vertical(topMargin),
          MainAppBar(title: formattedDate),
          CustomSpace.vertical(titleToImage),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // compute how much height is needed to dedicate to the tag section when focused
                // in order for the search bar to be on the top of the screen while we type so that
                // the results are visible underneath it despite the keyboard and the submit button
                final tagsHeight =
                    constraints.maxHeight -
                    CallToActionStyle.defaultStyle.height -
                    context.safe().bottom -
                    bottomMargin;

                return CustomScrollView(
                  // the tags section will use the scroll controller to scroll away the top part of this view while focused
                  controller: scrollController,
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        // Show parent post preview if in reply mode
                        if (parentPost != null)
                          ParentPostPreview(parentPost: parentPost!),
                        SizedBox(height: verticalSpacing),

                        // Show media selection only for non-text posts
                        if (contentCreation.data.contentType != ContentType.text &&
                            (contentCreation.mainImage != null ||
                                contentCreation.data.existingImageUrl != null ||
                                contentCreation.data.existingVideoUrl != null))
                          CustomPadding(
                            horizontal: horizontalPadding,
                            bottom: mediaToDescription,
                            child: ContentEditorSelectedMedia(
                              mediaFile: contentCreation.mainImage,
                              firstFrameFile: contentCreation.data.firstFrame,
                              thumbnailFile: contentCreation.thumbnail,
                              imageUrl: contentCreation.data.existingImageUrl,
                              videoUrl: contentCreation.data.existingVideoUrl,
                              thumbnailUrl:
                                  contentCreation.data.existingThumbnailUrl,
                              contentType: contentCreation.data.contentType,
                              onEdit: showMediaPicker,
                              onEditThumbnail: contentCreation.data.isVideo
                                  ? showThumbnailPicker
                                  : null,
                              onImageFlipped: contentCreation.updateImage,
                              isExtractingThumbnail: isExtractingThumbnail,
                            ),
                          ),

                        // Show text editor for text posts, description for media posts
                        CustomPadding(
                          horizontal: horizontalPadding,
                          bottom: verticalSpacing,
                          child: contentCreation.data.contentType == ContentType.text
                              ? ContentEditorTextPost(
                                  initialText: contentCreation.data.description,
                                  onChanged: contentCreation.updateDescription,
                                )
                              : ContentEditorPostDescription(
                                  initialText: contentCreation.data.description,
                                  onChanged: contentCreation.updateDescription,
                                ),
                        ),

                        CustomPadding(
                          horizontal: horizontalPadding,
                          child: ContentEditorPostTagUserSection(
                            taggedUserIds: contentCreation.data.taggedUserIds,
                            onTaggedUsersChanged:
                                contentCreation.updateTaggedUsers,
                            allUsers: allUsers,
                            scrollController: scrollController,
                            expandedHeight: tagsHeight,
                          ),
                        ),
                      ]),
                    ),

                    SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: CustomAlign.bottomCenter(
                        child: SafeArea(
                          top: false,
                          child: CustomPadding(
                            horizontal: horizontalPadding,
                            bottom: bottomMargin,
                            child: const ContentEditorButton(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
