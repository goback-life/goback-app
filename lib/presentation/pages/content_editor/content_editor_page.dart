import 'dart:io';

import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/media/domain/enums/media_type.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_picker.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_media_picker.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_thumbnail_picker.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/core/utilities/video_thumbnail_helper.dart';
import 'package:cloudless/presentation/components/error_view/main_error_view.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/pages/content_editor/views/content_editor_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ContentEditorPage extends HookConsumerWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentEditorData = ref.watch(postCreationNotifierProvider);
    final pendingLockoutId = ref.watch(pendingLockoutPostProvider);

    // Block direct editor access without lockout context (unless editing)
    // This is defense-in-depth; the post creation hook also enforces this
    final isEditing = contentEditorData.isEditing;
    final hasLockout = pendingLockoutId != null;
    if (!isEditing && !hasLockout) {
      // Schedule navigation after this build frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          router.go(HomeRoutable());
        }
      });
      return const SizedBox.shrink();
    }

    final contentCreation = usePostCreation(ref);
    final circleMembersData = useCircleMembers(ref);
    final asyncValue = ref.watch(getCircleMembersProvider);

    final parentPost = ref.watch(parentPostReferenceNotifierProvider);

    final allUsers = circleMembersData.allUsers;

    final isExtractingThumbnail = useState<bool>(false);
    final pickedFramePosition = useState<Duration?>(null);
    final isMediaSelectionLoading = useState(false);

    useLoadingOverlay(isMediaSelectionLoading, context: context);

    // Separate picker for images (creation and edit)
    final showImagePicker = useImagePicker(
      ref: ref,
      loadingNotifier: isMediaSelectionLoading,
      onImageSelected: (file) async {
        if (ref.context.mounted && file != null) {
          contentCreation.updateImage(file);
        }
      },
      enableCropping: false,
    );

    // Separate picker for videos (creation and edit)
    final showVideoPicker = useMediaPicker(
      ref: ref,
      loadingNotifier: isMediaSelectionLoading,
      forceMediaType: MediaType.video,
      onMediaSelected: (file) async {
        if (ref.context.mounted && file != null) {
          isExtractingThumbnail.value = true;
          contentCreation.updateImage(file);

          try {
            final firstFrame = await VideoThumbnailHelper.extractThumbnail(
              file,
            );

            if (ref.context.mounted) {
              contentCreation.updateFirstFrame(firstFrame);
            }
          } finally {
            isExtractingThumbnail.value = false;
          }
        }
      },
      enableCropping: false,
    );

    // For editing: use the appropriate picker based on content type
    final showMediaPicker = contentEditorData.isVideo
        ? showVideoPicker
        : showImagePicker;

    final String? videoUrl = contentCreation.data.isVideo
        ? contentCreation.mainImage?.path ??
              contentCreation.data.existingVideoUrl
        : null;

    final AsyncCallback? showThumbnailPicker = switch (videoUrl) {
      '' || null => null,
      final String videoUrl => useThumbnailPicker(
        ref: ref,
        videoUrl: videoUrl,
        initialPosition: pickedFramePosition.value ?? Duration.zero,
        onImageSelected: (pick) {
          if (ref.context.mounted && pick != null) {
            contentCreation.updateThumbnail(pick.file);
            pickedFramePosition.value = pick.position;
          }
        },
        enableCropping: false,
        cropType: CropType.content,
      ),
    };

    final locale = translator.currentLocale.toString();

    final String formattedDate = DateFormatter.formatFullDateTime(
      contentEditorData.effectiveCreatedAt,
      locale,
    );

    useEffect(() {
      // Cleanup only when leaving the page
      // Capture notifiers early to avoid using ref after disposal
      final notifier = ref.read(postCreationNotifierProvider.notifier);
      final parentPostNotifier = ref.read(
        parentPostReferenceNotifierProvider.notifier,
      );

      return () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.reset();
          parentPostNotifier.clear();
        });
      };
    }, []);

    useEffect(() {
      Future<void> extractFirstFrameFromExistingVideo() async {
        final data = contentEditorData;

        if (data.isVideo &&
            data.existingVideoUrl != null &&
            data.firstFrame == null &&
            !isExtractingThumbnail.value) {
          isExtractingThumbnail.value = true;

          try {
            final thumbnailPath =
                await VideoThumbnailHelper.extractThumbnailPath(
                  data.existingVideoUrl!,
                );

            if (thumbnailPath != null && ref.context.mounted) {
              final firstFrame = File(thumbnailPath);

              contentCreation.updateFirstFrame(firstFrame);
            }
          } finally {
            isExtractingThumbnail.value = false;
          }
        }
      }

      extractFirstFrameFromExistingVideo();
      return null;
    }, [contentEditorData.existingVideoUrl, contentEditorData.isVideo]);

    return MainDataLoader(
      provider: asyncValue,
      useScaffold: false,
      errorBuilder: (context, error) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topMargin),
              MainAppBar(title: formattedDate),
              SizedBox(height: titleToImage),
              Expanded(
                child: MainErrorView(
                  useScaffold: false,
                  onRetry: () {
                    ref.invalidate(getCircleMembersProvider);
                  },
                ),
              ),
            ],
          ),
        );
      },
      onRetry: () {
        ref.invalidate(getCircleMembersProvider);
      },
      builder: (context, members) {
        return ContentEditorView(
          contentCreation: contentCreation,
          showImagePicker: showImagePicker,
          showVideoPicker: showVideoPicker,
          showMediaPicker: showMediaPicker,
          showThumbnailPicker: showThumbnailPicker,
          allUsers: allUsers,
          formattedDate: formattedDate,
          parentPost: parentPost,
          isExtractingThumbnail: isExtractingThumbnail.value,
        );
      },
    );
  }
}
