import 'package:cloudless/presentation/components/form_field/former_pin_theme.dart';
import 'package:cloudless/presentation/components/form_field/otp_form_field.dart';
import 'package:cloudless/presentation/pages/join_circle/join_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class JoinCircleFormField extends HookConsumerWidget
    with MainLayout, JoinCircleLayout {
  const JoinCircleFormField({super.key});

  int get pinCodeLength => 6;

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
        final inviteCodeControl = form.control<String>('inviteCode');
        final hasError = inviteCodeControl.hasError('invalid');
        void confirmPaste(clippedText) {
          inviteCodeControl.value = clippedText;
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
                  OtpFormField.askPaste(
                    context: context,
                    confirmPaste: confirmPaste,
                    pinCodeLength: pinCodeLength,
                    theme: theme,
                  );
                  return false;
                },
                textCapitalization: TextCapitalization.characters,
                focusNode: focusNode,
                animationType: FormerPinAnimationTypes.none,
                cursorColor: colorScheme.tertiary,
                cursorHeight: cursorHeight,
                textStyle: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                control: inviteCodeControl,
                length: pinCodeLength,
                onSubmitted: (_) {
                  logger.info('Invite code submitted');
                },
                enableActiveFill: true,
                pinTheme: formerPinTheme(context, hasError: hasError),
                onCompleted: (value) {
                  logger.info('Invite code completed');
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
