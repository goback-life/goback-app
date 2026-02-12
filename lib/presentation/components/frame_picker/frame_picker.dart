import 'dart:io';

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/frame_picker/frames_progress_bar.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/video_player/video_player_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

typedef PickedFrame = ({File file, Duration position});
typedef PickedFramePath = ({String path, Duration position});

class FramePicker extends HookConsumerWidget
    with MainLayout, VideoPlayerLayout {
  const FramePicker({
    required this.videoUrl,
    required this.initialPosition,
    super.key,
  });

  final String videoUrl;
  final Duration initialPosition;

  bool get useConfirmButton => false;

  static Future<T?> show<T>({
    required BuildContext context,
    required String videoUrl,
    required Duration initialPosition,
    VoidCallback? onClose,
  }) => showDialog<T>(
    useSafeArea: false,
    barrierDismissible: false,
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) =>
        FramePicker(videoUrl: videoUrl, initialPosition: initialPosition),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLocalFile =
        !videoUrl.startsWith('http://') && !videoUrl.startsWith('https://');

    final controller = useMemoized(() {
      if (isLocalFile) {
        return VideoPlayerController.file(File(videoUrl));
      } else {
        return VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
    }, [videoUrl]);

    final isInitialized = useState(false);
    final isPlaying = useState(false);
    final isLoading = useState(true);
    final hasError = useState(false);
    final showControls = useState(true);

    useEffect(() {
      Future<void> initializePlayer() async {
        try {
          await controller.initialize();
          controller.seekTo(initialPosition);
          isInitialized.value = true;
          isLoading.value = false;
          isPlaying.value = false;

          controller.addListener(() {
            isPlaying.value = controller.value.isPlaying;
          });
        } catch (e) {
          hasError.value = true;
          isLoading.value = false;
        }
      }

      initializePlayer();

      return () {
        controller.dispose();
      };
    }, [controller]);

    // Auto-hide controls after 3 seconds
    useEffect(() {
      if (!showControls.value) {
        return null;
      }

      final timer = Future.delayed(
        Duration(seconds: controlsAutoHideDuration.toInt()),
        () {
          if (context.mounted && isPlaying.value) {
            showControls.value = false;
          }
        },
      );

      return () => timer.ignore();
    }, [showControls.value, isPlaying.value]);

    void toggleControls() {
      showControls.value = !showControls.value;
    }

    void togglePlayPause() {
      if (controller.value.isPlaying) {
        controller.pause();
        isPlaying.value = false;
      } else {
        controller.play();
        isPlaying.value = true;
      }
      // Show controls when play/pause is toggled
      if (!showControls.value) {
        showControls.value = true;
      }
    }

    void confirm() async {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1920,
        quality: 85,
        timeMs: controller.value.position.inMilliseconds,
      );
      if (context.mounted) {
        Navigator.of(
          context,
        ).pop((path: thumbnailPath, position: controller.value.position));
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildErrorView() => const SizedBox.shrink();

    Widget buildLoadingView() {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    Widget buildVideoPlayer() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video player
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),

                // Close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: showControls.value ? 1.0 : 0.0,
                    duration: Duration(
                      milliseconds: controlsAnimationDuration.toInt(),
                    ),
                    child: SafeArea(
                      child: Container(
                        margin: EdgeInsets.all(closeButtonMargin),
                        child: GestureDetector(
                          onTap: useConfirmButton
                              ? () => Navigator.of(context).pop(null)
                              : confirm,
                          child: AppGlassContainer(
                            config: GlassConfig(
                              variant: GlassVariant.regular,
                              cornerRadius: 999,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(closeButtonPadding),
                              child: Assets.svg.close.render(
                                colorFilter: colorScheme.primary.asSrcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Play/Pause button
                Center(
                  child: AnimatedOpacity(
                    opacity: showControls.value ? 1.0 : 0.0,
                    duration: Duration(
                      milliseconds: controlsAnimationDuration.toInt(),
                    ),
                    child: GestureDetector(
                      onTap: togglePlayPause,
                      child: Icon(
                        isPlaying.value ? Icons.pause : Icons.play_arrow,
                        color: colorScheme.primary,
                        size: playPauseIconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FramesProgressBar(
            controller: controller,
            videoUrl: videoUrl,
            useBottomSafeArea: !useConfirmButton,
          ),
          if (useConfirmButton)
            Container(
              color: colorScheme.surfaceDim,
              child: CustomPadding(
                top: framePickerConfirmButtonTopMargin,
                child: SafeArea(
                  top: false,
                  right: false,
                  left: false,
                  child: CallToAction(
                    action:
                        (isInitialized.value) &&
                            (!isLoading.value) &&
                            (!hasError.value)
                        ? confirm
                        : null,
                    label: Text(
                      translator.translate(
                        'components.frame_picker.confirm_frame',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: toggleControls,
      child: Container(
        color: colorScheme.secondary,
        child: SafeArea(
          bottom: hasError.value || (!isInitialized.value) || (isLoading.value),
          child: hasError.value
              ? buildErrorView()
              : isLoading.value
              ? buildLoadingView()
              : isInitialized.value
              ? buildVideoPlayer()
              : buildLoadingView(),
        ),
      ),
    );
  }
}
