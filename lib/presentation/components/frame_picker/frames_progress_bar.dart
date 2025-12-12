import 'package:cloudless/presentation/components/frame_picker/frame_preview.dart';
import 'package:cloudless/presentation/components/video_player/video_player_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FramesProgressBar extends StatelessWidget
    with MainLayout, VideoPlayerLayout {
  const FramesProgressBar({
    required this.controller,
    required this.videoUrl,
    required this.useBottomSafeArea,
    super.key,
  });

  final VideoPlayerController controller;
  final String videoUrl;
  final bool useBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      color: theme.colorScheme.surfaceDim,
      child: CustomPadding(
        horizontal: frameProgressBarHorizontalMargin,
        bottom: useBottomSafeArea ? context.safe().bottom : 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final target = framePickerFrameWidth;
            final int n = constraints.maxWidth ~/ target;
            return ConstrainedBox(
              constraints: constraints.copyWith(maxHeight: framePickerHeight),
              child: VideoScrubber(
                controller: controller,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: frameProgressBarVerticalMargin,
                      bottom: frameProgressBarVerticalMargin,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < n; i++)
                            Expanded(
                              child: FramePreview(
                                videoUrl: videoUrl,
                                index: i,
                                totalFrames: n,
                                controller: controller,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      top: frameProgressBarIndicatorVerticalMargin,
                      bottom: frameProgressBarIndicatorVerticalMargin,
                      child: ValueListenableBuilder(
                        valueListenable: controller,
                        child: Container(
                          width: 2,
                          height: framePickerHeight,
                          color: Colors.white,
                        ),
                        builder: (context, value, child) {
                          return Align(
                            alignment: Alignment(
                              (value.position.inMilliseconds /
                                          value.duration.inMilliseconds) *
                                      2 -
                                  1,
                              0,
                            ),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
