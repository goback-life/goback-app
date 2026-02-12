import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/core/utilities/video_thumbnail_helper.dart';
import 'package:cloudless/presentation/components/alerts/glass_warning_toast.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

const _maxVideoDurationSeconds = 60;

class CameraCaptureView extends HookConsumerWidget {
  const CameraCaptureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = useState<CameraController?>(null);
    final ready = useState(false);
    final recording = useState(false);
    final progress = useState(0.0);
    final processing = useState(false);
    final front = useState(false);
    final cams = useState<List<CameraDescription>>([]);

    useEffect(() {
      _initCamera(cams, ctrl, ready, front);
      return () => ctrl.value?.dispose();
    }, const []);

    useOnAppLifecycleStateChange((_, state) {
      if (ctrl.value == null || !ctrl.value!.value.isInitialized) return;
      if (state == AppLifecycleState.inactive) {
        ctrl.value?.dispose();
        ctrl.value = null;
        ready.value = false;
      } else if (state == AppLifecycleState.resumed) {
        _initCamera(cams, ctrl, ready, front);
      }
    });

    useEffect(() {
      if (!recording.value) { progress.value = 0.0; return null; }
      final t = Timer.periodic(const Duration(milliseconds: 100), (_) {
        progress.value += 0.1 / _maxVideoDurationSeconds;
        if (progress.value >= 1.0) {
          _stopRec(ctrl, recording, processing, ref, context);
        }
      });
      return t.cancel;
    }, [recording.value]);

    final pad = MediaQuery.of(context).padding;

    return Stack(fit: StackFit.expand, children: [
      if (ready.value && ctrl.value != null)
        Center(child: CameraPreview(ctrl.value!))
      else
        const Center(child: CircularProgressIndicator(color: Colors.white)),

      if (processing.value)
        Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),

      // Top bar
      Positioned(
        top: pad.top + 16, left: 16, right: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleBtn(Icons.close, () => Navigator.of(context).pop()),
            if (cams.value.length > 1)
              _CircleBtn(Icons.flip_camera_ios, () {
                front.value = !front.value;
                ctrl.value?.dispose();
                ready.value = false;
                _initCamera(cams, ctrl, ready, front);
              }),
          ],
        ),
      ),

      // Bottom bar
      Positioned(
        bottom: pad.bottom + 32, left: 0, right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _GalleryBtn(() => _pickGallery(ref, context, processing)),
            _ShutterBtn(
              recording: recording.value,
              progress: progress.value,
              onTap: () => _takePhoto(ctrl, processing, ref, context),
              onStart: () => _startRec(ctrl, recording, context),
              onEnd: () => _stopRec(ctrl, recording, processing, ref, context),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Camera lifecycle
// ---------------------------------------------------------------------------

Future<void> _initCamera(
  ValueNotifier<List<CameraDescription>> cams,
  ValueNotifier<CameraController?> ctrl,
  ValueNotifier<bool> ready,
  ValueNotifier<bool> front,
) async {
  try {
    final available = await availableCameras();
    cams.value = available;
    if (available.isEmpty) return;
    final dir = front.value ? CameraLensDirection.front : CameraLensDirection.back;
    final cam = available.firstWhere(
      (c) => c.lensDirection == dir,
      orElse: () => available.first,
    );
    final c = CameraController(cam, ResolutionPreset.high, enableAudio: true);
    await c.initialize();
    ctrl.value = c;
    ready.value = true;
  } catch (e) {
    logger.error('Camera init failed', exception: e);
  }
}

// ---------------------------------------------------------------------------
// Capture actions
// ---------------------------------------------------------------------------

Future<void> _takePhoto(
  ValueNotifier<CameraController?> ctrl,
  ValueNotifier<bool> processing,
  WidgetRef ref,
  BuildContext context,
) async {
  final c = ctrl.value;
  if (c == null || !c.value.isInitialized || processing.value) return;
  processing.value = true;
  try {
    final xFile = await c.takePicture();
    await HapticFeedback.mediumImpact();
    await ref.read(postCreationNotifierProvider.notifier).updateImage(File(xFile.path));
    if (context.mounted) await router.push(const ContentEditorRoutable());
  } catch (e) {
    logger.error('Photo capture failed', exception: e);
  } finally {
    processing.value = false;
  }
}

Future<void> _startRec(
  ValueNotifier<CameraController?> ctrl,
  ValueNotifier<bool> recording,
  BuildContext context,
) async {
  final c = ctrl.value;
  if (c == null || !c.value.isInitialized) return;
  final mic = await Permission.microphone.request();
  if (!mic.isGranted) {
    if (context.mounted) {
      await MainAlert.showFull(
        context: context,
        title: 'Microphone Permission',
        content: const Text('Microphone access is needed for video recording.'),
        primaryButtonText: 'Settings',
        onPrimaryPressed: () { Navigator.of(context).pop(); openAppSettings(); },
        secondaryButtonText: 'Cancel',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      );
    }
    return;
  }
  try {
    await c.startVideoRecording();
    recording.value = true;
    await HapticFeedback.heavyImpact();
  } catch (e) {
    logger.error('Start recording failed', exception: e);
  }
}

Future<void> _stopRec(
  ValueNotifier<CameraController?> ctrl,
  ValueNotifier<bool> recording,
  ValueNotifier<bool> processing,
  WidgetRef ref,
  BuildContext context,
) async {
  final c = ctrl.value;
  if (c == null || !recording.value) return;
  recording.value = false;
  processing.value = true;
  try {
    final xFile = await c.stopVideoRecording();
    await HapticFeedback.mediumImpact();
    final file = File(xFile.path);
    if (!await _validateDuration(file, context)) return;
    final notifier = ref.read(postCreationNotifierProvider.notifier);
    await notifier.updateImage(file);
    notifier.updateFirstFrame(await VideoThumbnailHelper.extractThumbnail(file));
    if (context.mounted) await router.push(const ContentEditorRoutable());
  } catch (e) {
    logger.error('Stop recording failed', exception: e);
  } finally {
    processing.value = false;
  }
}

Future<void> _pickGallery(
  WidgetRef ref,
  BuildContext context,
  ValueNotifier<bool> processing,
) async {
  processing.value = true;
  try {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ref.read(postCreationNotifierProvider.notifier).updateImage(File(image.path));
      if (context.mounted) await router.push(const ContentEditorRoutable());
      return;
    }
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      if (!await _validateDuration(file, context)) return;
      final notifier = ref.read(postCreationNotifierProvider.notifier);
      await notifier.updateImage(file);
      notifier.updateFirstFrame(await VideoThumbnailHelper.extractThumbnail(file));
      if (context.mounted) await router.push(const ContentEditorRoutable());
    }
  } catch (e) {
    logger.error('Gallery pick failed', exception: e);
  } finally {
    processing.value = false;
  }
}

/// Returns true if duration is valid, false otherwise.
Future<bool> _validateDuration(File file, BuildContext context) async {
  VideoPlayerController? c;
  try {
    c = VideoPlayerController.file(file);
    await c.initialize();
    if (c.value.duration.inSeconds > _maxVideoDurationSeconds) {
      if (context.mounted) {
        GlassWarningToast.show(context, 'Videos must be 60 seconds or less');
      }
      return false;
    }
  } catch (_) {
    // If we can't determine duration, allow it
  } finally {
    await c?.dispose();
  }
  return true;
}

// ---------------------------------------------------------------------------
// UI Components
// ---------------------------------------------------------------------------

class _CircleBtn extends StatelessWidget {
  const _CircleBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _GalleryBtn extends StatelessWidget {
  const _GalleryBtn(this.onTap);
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
    ),
  );
}

class _ShutterBtn extends StatelessWidget {
  const _ShutterBtn({
    required this.recording,
    required this.progress,
    required this.onTap,
    required this.onStart,
    required this.onEnd,
  });
  final bool recording;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: recording ? null : onTap,
    onLongPressStart: recording ? null : (_) => onStart(),
    onLongPressEnd: recording ? (_) => onEnd() : null,
    onLongPressCancel: recording ? onEnd : null,
    child: SizedBox(
      width: 80, height: 80,
      child: CustomPaint(painter: _ShutterPaint(recording, progress)),
    ),
  );
}

class _ShutterPaint extends CustomPainter {
  _ShutterPaint(this.recording, this.progress);
  final bool recording;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawCircle(center, recording ? r * 0.38 : r * 0.82, Paint()
      ..color = recording ? Colors.red : Colors.white);
    if (recording && progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = Colors.red..style = PaintingStyle.stroke
          ..strokeWidth = 4..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShutterPaint o) =>
      o.recording != recording || o.progress != progress;
}
