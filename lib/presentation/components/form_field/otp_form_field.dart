import 'package:cloudless/core/features/auth/domain/hooks/use_otp_form.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/form_field/former_pin_theme.dart';
import 'package:cloudless/presentation/pages/otp/otp_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled_text/styled_text.dart';

class OtpFormField extends HookConsumerWidget with MainLayout, OtpLayout {
  const OtpFormField({super.key});

  int get pinCodeLength => 6;

  static Future<void> askPaste({
    required BuildContext context,
    required void Function(String clippedText) confirmPaste,
    required int pinCodeLength,
    required ThemeData theme,
  }) async {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final clipboardData = await Clipboard.getData('text/plain');
    final text = (clipboardData?.text ?? '');
    final clippedText = text.length > pinCodeLength
        ? text.substring(0, pinCodeLength)
        : text;
    if (!context.mounted) {
      return;
    }
    if (clippedText.isNotEmpty) {
      MainAlert.showFull(
        context: context,
        title: translator.translate('components.alert.paste_otp_dialog.title'),
        content: StyledText(
          text: translator.translate(
            'components.alert.paste_otp_dialog.content',
            arguments: {'code': clippedText},
          ),
          tags: {
            'bold': StyledTextTag(
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          },
        ),
        primaryButtonText: translator.translate(
          'components.alert.paste_otp_dialog.paste',
        ),
        secondaryButtonText: translator.translate(
          'components.alert.paste_otp_dialog.cancel',
        ),
        onPrimaryPressed: () {
          confirmPaste(clippedText);
          router.pop();
        },
        onSecondaryPressed: () {
          router.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final hasEverFocused = useState(false);
    final isKeyboardOpen = useState(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          focusNode.requestFocus();
        }
      });
      return null;
    }, []);

    useEffect(() {
      void onFocusChange() {
        isKeyboardOpen.value = focusNode.hasFocus;
      }

      focusNode.addListener(onFocusChange);

      return () => focusNode.removeListener(onFocusChange);
    }, [focusNode]);

    return FormerFormConsumer(
      builder: (context, form, child) {
        final otpControl = form.control<String>(OtpFormKey.otp.value);
        final hasError = otpControl.hasError('invalid');

        void confirmPaste(String clippedText) {
          otpControl.value = clippedText;
        }

        return AbsorbPointer(
          absorbing: isKeyboardOpen.value,
          child: TapRegion(
            onTapOutside: (event) => context.unfocus(),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus && !hasEverFocused.value) {
                  hasEverFocused.value = true;
                }
              },
              child: FormerFormPincodeTextfield<String>(
                beforeTextPaste: (text) {
                  askPaste(
                    context: context,
                    confirmPaste: confirmPaste,
                    pinCodeLength: pinCodeLength,
                    theme: theme,
                  );
                  return false;
                },
                focusNode: focusNode,
                animationType: FormerPinAnimationTypes.none,
                cursorColor: colorScheme.tertiary,
                cursorHeight: cursorHeight,
                textStyle: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                control: otpControl,
                length: pinCodeLength,
                keyboardType: TextInputType.number,
                onSubmitted: (_) {
                  logger.info('OTP submitted');
                },
                enableActiveFill: true,
                pinTheme: formerPinTheme(context, hasError: hasError),
                onCompleted: (_) {
                  logger.info('OTP completed');
                },
                showErrors: (control) {
                  final String value = control.value ?? '';
                  if (control.hasFocus) {
                    return control.invalid &&
                        control.dirty &&
                        value.length == 6;
                  } else {
                    return hasEverFocused.value && control.invalid;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
