import 'package:cloudless/presentation/components/video_player/video_player_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Progress bar for video player.
class VideoProgressBar extends StatelessWidget
    with MainLayout, VideoPlayerLayout {
  const VideoProgressBar({
    required this.controller,
    required this.colorScheme,
    super.key,
  });

  final VideoPlayerController controller;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      controller,
      allowScrubbing: true,
      padding: EdgeInsets.symmetric(
        horizontal: progressBarHorizontalPadding,
        vertical: progressBarVerticalPadding,
      ),
      colors: VideoProgressColors(
        playedColor: colorScheme.primary,
        bufferedColor: colorScheme.primary.withValues(
          alpha: progressBarBufferedAlpha,
        ),
        backgroundColor: colorScheme.primary.withValues(
          alpha: progressBarBackgroundAlpha,
        ),
      ),
    );
  }
}
