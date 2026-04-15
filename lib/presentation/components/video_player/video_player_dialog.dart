import 'dart:io';

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/video_player/video_player_layout.dart';
import 'package:cloudless/presentation/components/video_player/video_progress_bar.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen dialog for playing videos.
///
/// Supports videos from URL or local file.
/// Includes play/pause controls and progress bar.
class VideoPlayerDialog extends HookConsumerWidget
    with MainLayout, VideoPlayerLayout {
  const VideoPlayerDialog({required this.videoUrl, this.onClose, super.key});

  final String videoUrl;
  final VoidCallback? onClose;

  /// Shows the dialog to play a video.
  static Future<T?> show<T>({
    required BuildContext context,
    required String videoUrl,
    VoidCallback? onClose,
  }) => showDialog<T>(
    useSafeArea: false,
    barrierDismissible: false,
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) =>
        VideoPlayerDialog(videoUrl: videoUrl, onClose: onClose),
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
          isInitialized.value = true;
          isLoading.value = false;
          controller.play();
          isPlaying.value = true;

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

    void handleClose() {
      Navigator.of(context).pop();
      onClose?.call();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildErrorView() {
      return const SizedBox.shrink();
    }

    Widget buildLoadingView() {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    Widget buildVideoPlayer() {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // Controls overlay
          Container(
            color: colorScheme.secondary.withValues(
              alpha: controlsOverlayAlpha,
            ),
            child: Stack(
              children: [
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
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: handleClose,
                        child: Container(
                          margin: EdgeInsets.all(closeButtonMargin),
                          padding: EdgeInsets.all(closeButtonPadding),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(
                              alpha: closeButtonBackgroundAlpha,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Assets.svg.close.render(
                            colorFilter: colorScheme.primary.asSrcIn,
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

                // Progress bar at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: VideoProgressBar(
                      controller: controller,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
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
