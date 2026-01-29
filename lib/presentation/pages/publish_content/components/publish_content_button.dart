import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PublishContentButton extends ConsumerWidget
    with MainLayout, PublishContentLayout {
  const PublishContentButton({required this.onTap, super.key});

  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final buttonText = translator.translate('pages.publish_content.button');

    return CallToAction.primary.filled(
      action: onTap,
      label: Text(
        buttonText,
        style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}
