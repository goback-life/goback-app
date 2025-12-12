import 'dart:io';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FramePreview extends HookConsumerWidget {
  const FramePreview({
    required this.videoUrl,
    required this.index,
    required this.totalFrames,
    required this.controller,
    super.key,
  });

  final String videoUrl;
  final int index;
  final int totalFrames;
  final VideoPlayerController controller;

  Future<String?> getFrame(Duration duration) async {
    return VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: (await Directory.systemTemp.createTemp()).path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 1920,
      quality: 85,
      timeMs: (duration.inMilliseconds / (totalFrames - 1) * index).round(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // launch init only once

    final frame = useState<String>('');

    useEffect(() {
      Future<void> init() async {
        final total = controller.value.duration;
        if (total.inMilliseconds <= 0) {
          return;
        }
        try {
          final path = await getFrame(total);
          if (path case final String path) {
            frame.value = path;
          }
        } catch (e) {
          frame.value = '';
        }
      }

      init();
      return () {};
    }, [videoUrl, controller.value.duration]);

    return Container(
      decoration: BoxDecoration(
        image: switch (frame.value) {
          '' => null,
          final String path => DecorationImage(
            image: FileImage(File(path)),
            fit: BoxFit.cover,
          ),
        },
      ),
    );
  }
}
