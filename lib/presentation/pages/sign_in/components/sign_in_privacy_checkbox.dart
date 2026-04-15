import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/hooks/use_privacy_policy_launch_url.dart';
import 'package:cloudless/presentation/hooks/use_terms_of_service_launch_url.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';

class SignInPrivacyCheckbox extends HookWidget with MainLayout, SignInLayout {
  const SignInPrivacyCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final openPrivacyPolicyUrl = usePrivacyPolicyLaunchUrl(
      translator.translate('pages.sign_in.privacy_policy_url'),
    );
    final openTermsOfServiceUrl = useTermsOfServiceLaunchUrl(
      translator.translate('pages.sign_in.terms_of_service_url'),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: checkBoxSize,
              height: checkBoxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(checkBoxBorderRadius),
                color: value
                    ? colorScheme.primaryContainer
                    : colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
              ),
              child: value
                  ? Assets.svg.check.render(
                      colorFilter: colorScheme.primary.asSrcIn,
                      width: checkSize,
                      height: checkSize,
                    )
                  : null,
            ),
            SizedBox(width: checkBoxToText),
            Expanded(
              child: StyledText(
                text: translator.translate('pages.sign_in.privacy_text'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                tags: {
                  'privacy': StyledTextActionTag(
                    (_, __) {
                      openPrivacyPolicyUrl();
                    },
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  'terms': StyledTextActionTag(
                    (_, __) {
                      openTermsOfServiceUrl();
                    },
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
