import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _currentStep = 0;

  static const _stepKeys = <({String titleKey, String descKey})>[
    (
      titleKey: 'pages.onboarding.step1_title',
      descKey: 'pages.onboarding.step1_description',
    ),
    (
      titleKey: 'pages.onboarding.step2_title',
      descKey: 'pages.onboarding.step2_description',
    ),
    (
      titleKey: 'pages.onboarding.step3_title',
      descKey: 'pages.onboarding.step3_description',
    ),
    (
      titleKey: 'pages.onboarding.step4_title',
      descKey: 'pages.onboarding.step4_description',
    ),
  ];

  void _next() {
    if (_currentStep < _stepKeys.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _stepKeys[_currentStep];
    final isLastStep = _currentStep == _stepKeys.length - 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // absorb taps
      child: Container(
        color: MainColors.dark.withValues(alpha: 0.88),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip button top-right
              Positioned(
                top: 16,
                right: 24,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: Text(
                    translator.translate('pages.onboarding.skip'),
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MainColors.grey500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              // Centered card
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AppGlassContainer(
                    config: const GlassConfig(cornerRadius: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 36,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            translator.translate(step.titleKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: MainFontFamilies.quicksand,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: MainColors.dark,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translator.translate(step.descKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: MainFontFamilies.quicksand,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: MainColors.dark,
                              decoration: TextDecoration.none,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Step indicator dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _stepKeys.length,
                              (i) => Container(
                                width: i == _currentStep ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i == _currentStep
                                      ? MainColors.accent
                                      : MainColors.grey300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Next / Got it button
                          CallToAction.filled.primary(
                            action: _next,
                            label: Text(
                              translator.translate(
                                isLastStep
                                    ? 'pages.onboarding.done'
                                    : 'pages.onboarding.next',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
