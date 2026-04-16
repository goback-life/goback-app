import 'dart:async';

import 'package:cloudless/core/features/connection/domain/hooks/use_join_circle.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_validate_invite_code.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Constants (Figma 106:207)
// ---------------------------------------------------------------------------

const _kCardRadius = 47.0;
const _kCodeLength = 6;
const _kCodeBoxGap = 8.0;
const _kCodeBoxAspect = 62.0 / 46.0; // h/w from Figma
const _kCodeBoxRadius = 47.0;
const _kSubmitHeight = 60.0;
const _kSubmitWidth = 231.0;
const _kSubmitRadius = 47.0;

/// Shows the receive-code card as a fade-in overlay (no background dimming).
Future<void> showReceiveCodeCardPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss code card',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (context, _, __) => Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const _ReceiveCodeCard(),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

enum _CardState { idle, validating, confirmed, joining, success, error }

// ---------------------------------------------------------------------------
// Main card
// ---------------------------------------------------------------------------

class _ReceiveCodeCard extends HookConsumerWidget {
  const _ReceiveCodeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardWidth = MediaQuery.of(context).size.width - 24;

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final code = useState('');
    final cardState = useState(_CardState.idle);
    final errorMsg = useState('');
    final creatorName = useState('');
    final resetTimer = useRef<Timer?>(null);
    final dismissTimer = useRef<Timer?>(null);

    final validateCode = useValidateInviteCode(ref);
    final joinCircle = useJoinCircle(ref);

    // Cleanup timers on dispose.
    useEffect(() {
      return () {
        resetTimer.value?.cancel();
        dismissTimer.value?.cancel();
      };
    }, []);

    // Auto-focus the hidden field so keyboard opens immediately.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
      return null;
    }, []);

    // Auto-validate when all 6 characters are entered.
    useEffect(() {
      if (code.value.length != _kCodeLength) return null;
      if (cardState.value != _CardState.idle) return null;

      cardState.value = _CardState.validating;

      () async {
        final result = await validateCode(code.value);
        if (!context.mounted) return;

        result.fold(
          (validation) => validation.when(
            valid: (profile) {
              creatorName.value = profile['username'] as String? ?? 'Unknown';
              cardState.value = _CardState.confirmed;
            },
            invalid: (msg) {
              errorMsg.value = msg;
              cardState.value = _CardState.error;
            },
          ),
          (error) {
            errorMsg.value = _friendlyError(error);
            cardState.value = _CardState.error;
          },
        );
      }();

      return null;
    }, [code.value]);

    // Clear boxes and reset after error.
    useEffect(() {
      if (cardState.value != _CardState.error) return null;
      HapticFeedback.heavyImpact();
      resetTimer.value?.cancel();
      resetTimer.value = Timer(const Duration(seconds: 2), () {
        if (!context.mounted) return;
        code.value = '';
        controller.clear();
        cardState.value = _CardState.idle;
        errorMsg.value = '';
        focusNode.requestFocus();
      });
      return null;
    }, [cardState.value]);

    // Auto-dismiss after success.
    useEffect(() {
      if (cardState.value != _CardState.success) return null;
      HapticFeedback.mediumImpact();
      dismissTimer.value?.cancel();
      dismissTimer.value = Timer(const Duration(milliseconds: 800), () {
        if (context.mounted) Navigator.of(context).pop();
      });
      return null;
    }, [cardState.value]);

    Future<void> onSubmit() async {
      if (cardState.value != _CardState.confirmed) return;
      cardState.value = _CardState.joining;

      final result = await joinCircle(code.value);
      if (!context.mounted) return;

      result.fold(
        (_) {
          ref.invalidate(getCircleMembersProvider);
          cardState.value = _CardState.success;
        },
        (error) {
          errorMsg.value = _friendlyError(error);
          cardState.value = _CardState.error;
        },
      );
    }

    final subtitle = switch (cardState.value) {
      _CardState.idle => "Enter your friend's code",
      _CardState.validating => 'Checking...',
      _CardState.confirmed => 'Add ${creatorName.value}?',
      _CardState.joining => 'Adding...',
      _CardState.success => 'Added!',
      _CardState.error => errorMsg.value,
    };

    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = switch (cardState.value) {
      _CardState.error => colorScheme.onSurface.withValues(alpha: 0.4),
      _CardState.success => MainColors.accent,
      _ => colorScheme.onSurface,
    };

    final canSubmit = cardState.value == _CardState.confirmed;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: cardWidth,
        child: AppGlassContainer(
          config: const GlassConfig(
            tint: MainColors.accent,
            cornerRadius: _kCardRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "What's the magic number?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w600,
                    fontSize: 27,
                    color: MainColors.dark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // State-driven subtitle.
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w400,
                    fontSize: 24,
                    color: accentColor,
                    letterSpacing: -0.3,
                  ),
                  child: Text(subtitle, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 36),
                // 6 code boxes with hidden input.
                _CodeBoxes(
                  controller: controller,
                  focusNode: focusNode,
                  code: code.value,
                  charColor: accentColor,
                  enabled: cardState.value == _CardState.idle,
                  onChanged: (t) => code.value = t.toUpperCase(),
                ),
                const SizedBox(height: 36),
                // Submit pill.
                GestureDetector(
                  onTap: canSubmit ? onSubmit : null,
                  child: AnimatedOpacity(
                    opacity: canSubmit ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: _kSubmitWidth,
                      height: _kSubmitHeight,
                      child: AppGlassContainer(
                        config: const GlassConfig(
                          tint: MainColors.accent,
                          cornerRadius: _kSubmitRadius,
                        ),
                        child: Center(
                          child: Text(
                            cardState.value == _CardState.joining
                                ? 'Adding...'
                                : 'Submit',
                            style: const TextStyle(
                              fontFamily: MainFontFamilies.quicksand,
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                              color: MainColors.dark,
                              letterSpacing: -0.3,
                            ),
                          ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Code boxes — 6 responsive glass pills driven by one hidden TextField
// ---------------------------------------------------------------------------

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.charColor,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final Color charColor;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGaps = (_kCodeLength - 1) * _kCodeBoxGap;
        final boxW = (constraints.maxWidth - totalGaps) / _kCodeLength;
        final boxH = boxW * _kCodeBoxAspect;

        return GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: SizedBox(
            height: boxH,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_kCodeLength, (i) {
                    final char = i < code.length ? code[i] : '';
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < _kCodeLength - 1 ? _kCodeBoxGap : 0,
                      ),
                      child: SizedBox(
                        width: boxW,
                        height: boxH,
                        child: AppGlassContainer(
                          config: const GlassConfig(
                            tint: MainColors.accent,
                            cornerRadius: _kCodeBoxRadius,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 100),
                              child: Text(
                                char,
                                key: ValueKey('box$i-$char'),
                                style: TextStyle(
                                  fontFamily: MainFontFamilies.quicksand,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                  color: charColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Invisible TextField captures all keyboard input.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      enabled: enabled,
                      maxLength: _kCodeLength,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Error mapping
// ---------------------------------------------------------------------------

String _friendlyError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('self') || msg.contains('own')) return "Can't add yourself";
  if (msg.contains('already')) return 'Already friends';
  if (msg.contains('expired')) return 'Code expired';
  if (msg.contains('used')) return 'Code already used';
  if (msg.contains('limit') || msg.contains('150')) return 'Circle is full';
  return 'Invalid code';
}
