import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class OtpResendCode extends HookWidget {
  const OtpResendCode({required this.onResendCode, super.key});

  final Future<void> Function({bool showFeedback}) onResendCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isResending = useState<bool>(false);

    return GestureDetector(
      onTap: isResending.value
          ? null
          : () async {
              isResending.value = true;

              try {
                await onResendCode(showFeedback: true);
              } finally {
                isResending.value = false;
              }
            },
      child: Text(
        isResending.value
            ? translator.translate('pages.otp.resend_texts.sending')
            : translator.translate('pages.otp.resend_code'),
        style: textTheme.bodyMedium?.copyWith(
          color: isResending.value
              ? colorScheme.onSurface.withValues(alpha: 0.5)
              : colorScheme.onSurface,
          decoration: isResending.value ? null : TextDecoration.underline,
        ),
      ),
    );
  }
}
