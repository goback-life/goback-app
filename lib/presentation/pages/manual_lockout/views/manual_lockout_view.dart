import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_live_activity_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/lockout/domain/utilities/goback_score_calculator.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/lockout_friends_overlay.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Restyled lockout page with sky cutout effect.
///
/// Solid inverted background (dark in light mode, white in dark mode) with
/// timer text and decorative triangle acting as cutout windows revealing the
/// sky image beneath. When the timer reaches 0:00, transitions in-place to
/// a share/skip prompt.
class ManualLockoutView extends HookConsumerWidget {
  const ManualLockoutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = Theme.of(context).colorScheme.surface;
    final bgColor = surface.computeLuminance() < 0.5
        ? MainColors.white
        : MainColors.dark;

    final lockoutStateAsync = ref.watch(manualLockoutNotifierProvider);
    final countdown = useState('');
    final isLockoutComplete = useState(false);
    final sessionId = useState<String>('');
    final gobackScore = useState<int?>(null);
    final lockoutDurationMinutes = useState<int>(0);

    // Animation controllers for lockout-end transition
    final triangleFadeCtrl = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final textFadeCtrl = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );
    final triangleOpacity = useAnimation(
      Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: triangleFadeCtrl, curve: Curves.easeOut),
      ),
    );
    final completionTextOpacity = useAnimation(
      Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: textFadeCtrl, curve: Curves.easeIn)),
    );

    // Post creation hook for share flow
    final postCreationInit = usePostCreationInitialization(
      ref,
      skipContentTypePicker: true,
    );

    // Fetch session ID on mount
    useEffect(() {
      ref.read(manualLockoutStorableProvider).getLockoutSessionId().then((id) {
        sessionId.value = id ?? '';
      });
      return null;
    }, const []);

    // Friends overlay state
    final showFriendsOverlay = useState(false);

    // Compute goback score and trigger completion transition
    Future<void> onLockoutComplete() async {
      if (isLockoutComplete.value) return;
      isLockoutComplete.value = true;
      countdown.value = '0:00';
      ref.read(lockoutLiveActivityServiceProvider).endActivity();

      // Compute score from battery data
      final storable = ref.read(manualLockoutStorableProvider);
      final batteryStart = await storable.getBatteryAtStart();
      final lockoutStart = await storable.getLockoutStart();

      if (lockoutStart != null) {
        final duration = DateTime.now().difference(lockoutStart);
        lockoutDurationMinutes.value = duration.inMinutes;

        int? batteryEnd;
        try {
          batteryEnd = await Battery().batteryLevel;
        } catch (e) {
          logger.warning('Battery read failed', exception: e);
        }

        final score = GobackScoreCalculator.calculate(
          batteryStart: batteryStart,
          batteryEnd: batteryEnd,
          duration: duration,
        );
        gobackScore.value = score;

        // Upload score to server
        final sid = sessionId.value;
        if (score != null && sid.isNotEmpty) {
          final sessionService = ref.read(lockoutSessionServiceProvider);
          await sessionService.updateScore(sessionId: sid, score: score);
        }
      }

      triangleFadeCtrl.forward().then((_) {
        textFadeCtrl.forward();
      });
    }

    // Timer logic
    useEffect(() {
      Timer? timer;

      lockoutStateAsync.whenData((lockoutState) {
        if (!lockoutState.isLockedOut && !isLockoutComplete.value) {
          onLockoutComplete();
          return;
        }

        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          ref.read(manualLockoutNotifierProvider.notifier).refresh().then((_) {
            final updated = ref.read(manualLockoutNotifierProvider);
            updated.whenData((state) {
              if (state.isLockedOut && state.remainingDuration != null) {
                countdown.value = _formatDuration(state.remainingDuration!);
              } else if (!isLockoutComplete.value) {
                onLockoutComplete();
              }
            });
          });
        });

        if (lockoutState.remainingDuration != null) {
          countdown.value = _formatDuration(lockoutState.remainingDuration!);
        }
      });

      return () => timer?.cancel();
    }, [lockoutStateAsync]);

    return GestureDetector(
      onLongPress: () {
        showFriendsOverlay.value = true;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Sky image (full screen, revealed through cutouts)
          Assets.png.backgroundGoback.render(
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Layer 2: Solid bg with cutout holes painted via saveLayer
          Positioned.fill(
            child: CustomPaint(
              painter: _CutoutPainter(
                bgColor: bgColor,
                countdown: countdown.value,
                triangleOpacity: triangleOpacity,
                completionTextOpacity: completionTextOpacity,
                isComplete: isLockoutComplete.value,
                gobackScore: gobackScore.value,
                lockoutDurationMinutes: lockoutDurationMinutes.value,
              ),
            ),
          ),

          // Layer 3: Invisible tap targets for share/skip (only during completion)
          if (isLockoutComplete.value && completionTextOpacity > 0)
            _CompletionTapTargets(
              opacity: completionTextOpacity,
              onShare: () =>
                  _handleShare(ref, sessionId.value, postCreationInit),
              onSkip: () => _handleSkip(ref, sessionId.value),
            ),

          // Friends overlay
          if (showFriendsOverlay.value)
            Positioned.fill(
              child: LockoutFriendsOverlay(
                onDismiss: () => showFriendsOverlay.value = false,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    // Ceil to next whole minute so the display doesn't drop a minute early.
    final totalMinutes = (duration.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  void _handleShare(
    WidgetRef ref,
    String lockoutSessionId,
    PostCreationInitializationResult postCreationInit,
  ) {
    // Dismiss completion UI (preserves local storage for post creation hook)
    ref.read(manualLockoutNotifierProvider.notifier).dismissCompletion();
    if (lockoutSessionId.isNotEmpty) {
      ref
          .read(pendingLockoutPostProvider.notifier)
          .setLockoutId(lockoutSessionId);
    }
    postCreationInit.selectMainImage();
  }

  Future<void> _handleSkip(WidgetRef ref, String lockoutSessionId) async {
    final storable = ref.read(manualLockoutStorableProvider);

    if (lockoutSessionId.isNotEmpty) {
      final userStartedAt = await storable.getLockoutStart();
      final sessionService = ref.read(lockoutSessionServiceProvider);
      await sessionService.completeSessionWithoutPost(
        lockoutSessionId,
        userStartedAt: userStartedAt,
      );
    }

    await storable.clearLockout();
    // Clear completion-pending so nav overlay unblocks
    await ref.read(manualLockoutNotifierProvider.notifier).clearLockout();
    router.go(const HomeRoutable());
  }
}

/// Invisible positioned tap targets aligned with the painted share/skip text.
class _CompletionTapTargets extends StatelessWidget {
  const _CompletionTapTargets({
    required this.opacity,
    required this.onShare,
    required this.onSkip,
  });

  final double opacity;
  final VoidCallback onShare;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Must match _CutoutPainter fixed screen fractions
    final shareY = screenSize.height * 0.78;
    final skipY = screenSize.height * 0.87;

    return Stack(
      children: [
        Positioned(
          top: shareY,
          left: 0,
          right: 0,
          height: 60,
          child: GestureDetector(
            onTap: onShare,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: skipY,
          left: 0,
          right: 0,
          height: 36,
          child: GestureDetector(
            onTap: onSkip,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws a solid background with transparent cutouts
/// for the timer text, triangle, and completion text.
///
/// Uses [Canvas.saveLayer] + [BlendMode.clear] to punch holes through
/// the solid background, revealing the sky image beneath.
class _CutoutPainter extends CustomPainter {
  _CutoutPainter({
    required this.bgColor,
    required this.countdown,
    required this.triangleOpacity,
    required this.completionTextOpacity,
    required this.isComplete,
    this.gobackScore,
    this.lockoutDurationMinutes = 0,
  });

  final Color bgColor;
  final String countdown;
  final double triangleOpacity;
  final double completionTextOpacity;
  final bool isComplete;
  final int? gobackScore;
  final int lockoutDurationMinutes;

  /// Creates a foreground paint that punches holes via dstOut.
  /// Where text/shape is drawn (alpha > 0), the solid bg becomes transparent,
  /// revealing the sky image beneath.
  Paint _holePaint([double opacity = 1.0]) => Paint()
    ..blendMode = BlendMode.dstOut
    ..color = Colors.white.withValues(alpha: opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Compositing group: everything inside is blended together,
    // then composited as a unit onto the widget tree.
    canvas.saveLayer(rect, Paint());

    // 1. Solid background fill
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 2. Punch timer text hole using dstOut foreground paint
    if (countdown.isNotEmpty) {
      final timerFontSize = size.width * 0.8;
      final timerLetterSpacing = size.width * -0.04;
      final tp = TextPainter(
        text: TextSpan(
          text: countdown,
          style: TextStyle(
            fontFamily: MainFontFamilies.lilitaOne,
            fontSize: timerFontSize,
            letterSpacing: timerLetterSpacing,
            height: 1.0,
            foreground: _holePaint(),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Scale to fill screen width (scale up or down as needed)
      final targetW = size.width * 0.95;
      final scale = targetW / tp.width;
      final timerY = size.height * 0.35;
      final timerX = (size.width - tp.width * scale) / 2;

      canvas.save();
      canvas.translate(timerX, timerY);
      canvas.scale(scale);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // 3. Punch triangle hole (fades out on completion)
    if (triangleOpacity > 0) {
      final triangleH = size.width * 0.35;
      final triangleW = triangleH * 86 / 102;
      final triangleX = (size.width - triangleW) / 2;
      final triangleY = size.height - size.height * 0.08 - triangleH;
      final path = _trianglePath(Size(triangleW, triangleH));

      canvas.save();
      canvas.translate(triangleX, triangleY);
      canvas.drawPath(path, _holePaint(triangleOpacity));
      canvas.restore();
    }

    // 4. Punch goback score hole (between timer and share/skip)
    if (isComplete && completionTextOpacity > 0 && gobackScore != null) {
      final dH = lockoutDurationMinutes ~/ 60;
      final dM = lockoutDurationMinutes % 60;
      final durationStr = '$dH:${dM.toString().padLeft(2, '0')}';
      final scoreStr = '$gobackScore | $durationStr';

      final scoreTp = TextPainter(
        text: TextSpan(
          text: scoreStr,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 28,
            letterSpacing: 1.0,
            foreground: _holePaint(completionTextOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final scoreY = size.height * 0.68;
      scoreTp.paint(canvas, Offset((size.width - scoreTp.width) / 2, scoreY));

      // Label: "score / 100 | time"
      final labelTp = TextPainter(
        text: TextSpan(
          text: 'score / 100 | time',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            letterSpacing: 0.5,
            foreground: _holePaint(completionTextOpacity * 0.5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset((size.width - labelTp.width) / 2, scoreY + scoreTp.height + 6),
      );
    }

    // 5. Punch completion text holes ("Share your goback" + "Skip")
    // Positioned at fixed screen fractions matching Figma (157:50).
    if (isComplete && completionTextOpacity > 0) {
      final shareY = size.height * 0.78;
      final skipY = size.height * 0.87;

      final shareTp = TextPainter(
        text: TextSpan(
          text: 'Share your goback',
          style: TextStyle(
            fontFamily: MainFontFamilies.lilitaOne,
            fontSize: 48,
            foreground: _holePaint(completionTextOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final skipTp = TextPainter(
        text: TextSpan(
          text: 'Skip',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 24,
            foreground: _holePaint(completionTextOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      shareTp.paint(canvas, Offset((size.width - shareTp.width) / 2, shareY));
      skipTp.paint(canvas, Offset((size.width - skipTp.width) / 2, skipY));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) =>
      oldDelegate.bgColor != bgColor ||
      oldDelegate.countdown != countdown ||
      oldDelegate.triangleOpacity != triangleOpacity ||
      oldDelegate.completionTextOpacity != completionTextOpacity ||
      oldDelegate.isComplete != isComplete ||
      oldDelegate.gobackScore != gobackScore ||
      oldDelegate.lockoutDurationMinutes != lockoutDurationMinutes;
}

/// Triangle path matching feed_lockout_button (viewBox 86x102).
Path _trianglePath(Size size) {
  final sx = size.width / 86.0;
  final sy = size.height / 102.0;

  return Path()
    ..moveTo(10.0244 * sx, 55.1414 * sy)
    ..cubicTo(
      1.42744 * sx,
      48.7205 * sy,
      2.1564 * sx,
      35.6124 * sy,
      11.4122 * sx,
      30.1843 * sy,
    )
    ..lineTo(59.3289 * sx, 2.0836 * sy)
    ..cubicTo(
      69.3286 * sx,
      -3.7807 * sy,
      81.917 * sx,
      3.43033 * sy,
      81.917 * sx,
      15.0227 * sy,
    )
    ..lineTo(81.917 * sx, 78.9116 * sy)
    ..cubicTo(
      81.917 * sx,
      91.2584 * sy,
      67.8333 * sx,
      98.3179 * sy,
      57.941 * sx,
      90.9295 * sy,
    )
    ..lineTo(10.0244 * sx, 55.1414 * sy)
    ..close();
}
