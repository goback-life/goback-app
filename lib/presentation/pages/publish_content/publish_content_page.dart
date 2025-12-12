import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_layout.dart';
import 'package:cloudless/presentation/pages/publish_content/views/publish_content_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PublishContentPage extends HookConsumerWidget
    with MainLayout, PublishContentLayout {
  const PublishContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentEditorData = ref.watch(postCreationNotifierProvider);

    final locale = translator.currentLocale.toString();

    final formattedDate = DateFormatter.formatFullDateTime(
      contentEditorData.effectiveCreatedAt,
      locale,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topMargin),
          MainAppBar(title: formattedDate),
          SizedBox(height: titleToImage),
          const Expanded(child: PublishContentView()),
        ],
      ),
    );
  }
}
