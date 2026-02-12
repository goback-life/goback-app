import 'dart:async';

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/components/goback_logo.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/components/time_limit_reached_exit_button.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class TimeLimitReachedView extends HookConsumerWidget
    with MainLayout, TimeLimitReachedLayout {
  const TimeLimitReachedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final countdown = useState('');

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        countdown.value = _getCountdownToMidnight();
      });

      return timer.cancel;
    }, []);

    return BackgroundImage(
      backgroundImage: Assets.png.backgroundGoback.provider(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6],
            colors: [
              colorScheme.secondary.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: topPadding),
                  Text(
                    translator.translate('pages.time_limit_reached.title'),
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  GobackLogo(fontSize: logoSize * 0.6),
                  const Spacer(flex: 3),
                  const TimeLimitReachedExitButton(),
                  SizedBox(height: buttonBottomPadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCountdownToMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final difference = midnight.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
