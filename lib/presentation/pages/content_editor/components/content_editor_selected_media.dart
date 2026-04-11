import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/full_screen_image.dart';
import 'package:cloudless/presentation/components/video_player/video_player_dialog.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ContentEditorSelectedMedia extends HookConsumerWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorSelectedMedia({
    this.mediaFile,
    this.imageUrl,
    this.videoUrl,
    this.firstFrameFile,
    this.thumbnailFile,
    this.thumbnailUrl,
    this.contentType = ContentType.image,
    this.onEdit,
    this.onEditThumbnail,
    this.onImageFlipped,
    this.isExtractingThumbnail = false,
    super.key,
  });

  final File? mediaFile;
  final String? imageUrl;
  final String? videoUrl;
  final File? firstFrameFile;
  final File? thumbnailFile;
  final String? thumbnailUrl;
  final ContentType contentType;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onEditThumbnail;
  final Future<void> Function(File)? onImageFlipped;
  final bool isExtractingThumbnail;

  ImageProvider? get _thumbnailImageProvider {
    if (thumbnailFile case final File thumbnailFile) {
      return FileImage(thumbnailFile);
    }
    if (thumbnailUrl case final String thumbnailUrl) {
      return CachedNetworkImageProvider(thumbnailUrl);
    }
    if (firstFrameFile case final File firstFrameFile) {
      return FileImage(firstFrameFile);
    }
    return null;
  }

  Widget _buildMediaPreview() {
    final bool isVideo = contentType == ContentType.video;

    if (isVideo && isExtractingThumbnail) {
      return Container(color: MainColors.white, child: const SizedBox.shrink());
    }

    if (isVideo && firstFrameFile != null) {
      return Image.file(firstFrameFile!, fit: BoxFit.cover);
    }

    if (isVideo && thumbnailUrl != null) {
      return CachedNetworkImage(imageUrl: thumbnailUrl!, fit: BoxFit.cover);
    }

    if (mediaFile != null) {
      // Use file size + timestamp as key to force refresh when file changes
      final fileKey =
          '${mediaFile!.path}_${mediaFile!.lengthSync()}_${mediaFile!.lastModifiedSync().millisecondsSinceEpoch}';
      return Image.file(mediaFile!, fit: BoxFit.cover, key: ValueKey(fileKey));
    }

    if (imageUrl != null) {
      return CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover);
    }

    return const SizedBox();
  }

  /// Writes flipped bytes to [file], invalidates caches, and notifies via [onImageFlipped].
  Future<void> _applyFlip(List<int> bytes, File file) async {
    await file.writeAsBytes(bytes, flush: true);
    await file.setLastModified(DateTime.now());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (onImageFlipped != null) {
      await onImageFlipped!(file);
    }
  }

  /// Shows [FullScreenImage] with flip handlers wired to [file].
  void _showFullScreenWithFlip(
    BuildContext context, {
    required ImageProvider image,
    required bool showFlipMenu,
    required File file,
  }) {
    FullScreenImage.show(
      context: context,
      image: image,
      showFlipMenu: showFlipMenu,
      onFlipHorizontal: showFlipMenu
          ? (bytes) => _applyFlip(bytes, file)
          : null,
      onFlipVertical: showFlipMenu ? (bytes) => _applyFlip(bytes, file) : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final bool isVideo = contentType == ContentType.video;

    // State to hold downloaded image file when editing with imageUrl
    final downloadedFile = useState<File?>(null);

    // Download image from URL if needed (edit mode without local file)
    Future<void> downloadImageIfNeeded() async {
      if (imageUrl != null &&
          mediaFile == null &&
          downloadedFile.value == null) {
        try {
          final response = await http.get(Uri.parse(imageUrl!));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final tempDir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempFile = File(
              '${tempDir.path}/downloaded_image_$timestamp.png',
            );
            await tempFile.writeAsBytes(bytes);
            downloadedFile.value = tempFile;
          }
        } catch (e) {
          // Silently fail - user can retry
        }
      }
    }

    // Show flip menu for images (not videos) during creation/editing
    final bool showFlipMenu =
        !isVideo &&
        onImageFlipped != null &&
        (mediaFile != null || imageUrl != null);

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (isVideo && (mediaFile != null || videoUrl != null)) {
              VideoPlayerDialog.show(
                context: context,
                videoUrl: mediaFile?.path ?? videoUrl!,
              );
            } else if (mediaFile != null) {
              final imageProvider = FileImage(mediaFile!);
              await imageProvider.evict();
              if (!context.mounted) return;

              _showFullScreenWithFlip(
                context,
                image: imageProvider,
                showFlipMenu: showFlipMenu,
                file: mediaFile!,
              );
            } else if (imageUrl != null) {
              if (downloadedFile.value == null && showFlipMenu) {
                await downloadImageIfNeeded();
                if (!context.mounted) return;

                if (downloadedFile.value != null) {
                  final imageProvider = FileImage(downloadedFile.value!);
                  await imageProvider.evict();
                  if (!context.mounted) return;

                  _showFullScreenWithFlip(
                    context,
                    image: imageProvider,
                    showFlipMenu: showFlipMenu,
                    file: downloadedFile.value!,
                  );
                } else {
                  if (!context.mounted) return;
                  FullScreenImage.show(
                    context: context,
                    image: CachedNetworkImageProvider(imageUrl!),
                  );
                }
              } else if (downloadedFile.value != null) {
                final imageProvider = FileImage(downloadedFile.value!);
                await imageProvider.evict();
                if (!context.mounted) return;

                _showFullScreenWithFlip(
                  context,
                  image: imageProvider,
                  showFlipMenu: showFlipMenu,
                  file: downloadedFile.value!,
                );
              } else {
                if (!context.mounted) return;
                FullScreenImage.show(
                  context: context,
                  image: CachedNetworkImageProvider(imageUrl!),
                );
              }
            }
          },
          child: Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaPreview(),

                  if (isVideo && !isExtractingThumbnail)
                    Center(child: Assets.svg.play.render()),
                  if (isVideo && !isExtractingThumbnail)
                    if (_thumbnailImageProvider
                        case final ImageProvider thumbnailImageProvider)
                      Positioned(
                        bottom: thumbnailPreviewBottomSpacing,
                        right: thumbnailPreviewRightSpacing,
                        width: thumbnailPreviewWidth,
                        height: thumbnailPreviewHeight,
                        child: GestureDetector(
                          onTap: onEditThumbnail,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                thumbnailPreviewBorderRadius,
                              ),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              image: DecorationImage(
                                image: thumbnailImageProvider,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: imageToEdit),
        GestureDetector(
          onTap: onEdit,
          child: Text(
            translator.translate('pages.content_editor.edit_content'),
            style: textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
