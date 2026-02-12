import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class SettingsMenuItem extends HookConsumerWidget
    with MainLayout, SettingsLayout {
  const SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.hasIndicator = false,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool hasIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          icon,
          SizedBox(width: circleToText),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (hasIndicator)
            AppGlassContainer(
              config: GlassConfig(
                variant: GlassVariant.regular,
                cornerRadius: width / 2,
                tint: colorScheme.primaryContainer,
              ),
              child: SizedBox(width: width, height: height),
            ),
          if (!hasIndicator)
            Assets.svg.next.render(colorFilter: colorScheme.onSurface.asSrcIn),
        ],
      ),
    );
  }
}
