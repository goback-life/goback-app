import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/hooks/use_privacy_policy_launch_url.dart';
import 'package:cloudless/presentation/hooks/use_terms_of_service_launch_url.dart';
import 'package:cloudless/presentation/pages/settings/components/settings_menu_item.dart';
import 'package:cloudless/presentation/pages/settings/hooks/use_assistance_launch_url.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class AssistanceLegalSection extends HookConsumerWidget
    with MainLayout, SettingsLayout {
  const AssistanceLegalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final openAssistanceUrl = useAssistanceLaunchUrl(
      translator.translate('pages.settings.assistance_url'),
    );
    final openPrivacyPolicyUrl = usePrivacyPolicyLaunchUrl(
      translator.translate('pages.sign_in.privacy_policy_url'),
    );
    final openTermsOfServiceUrl = useTermsOfServiceLaunchUrl(
      translator.translate('pages.sign_in.terms_of_service_url'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translator.translate('pages.settings.assistance_legal'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: titleSectionToElement),

        SettingsMenuItem(
          icon: Assets.svg.assistance.render(
            colorFilter: colorScheme.onSurface.asSrcIn,
          ),
          title: translator.translate('pages.settings.assistance'),
          onTap: openAssistanceUrl,
        ),

        SizedBox(height: verticalSpacing),

        SettingsMenuItem(
          icon: Assets.svg.privacyPolicy.render(
            colorFilter: colorScheme.onSurface.asSrcIn,
          ),
          title: translator.translate('pages.settings.privacy_policy'),
          onTap: openPrivacyPolicyUrl,
        ),

        SizedBox(height: verticalSpacing),

        SettingsMenuItem(
          icon: Assets.svg.termsConditions.render(
            colorFilter: colorScheme.onSurface.asSrcIn,
          ),
          title: translator.translate('pages.settings.terms_conditions'),
          onTap: openTermsOfServiceUrl,
        ),
      ],
    );
  }
}
