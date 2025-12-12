import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ContentEditorUserChip extends StatelessWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorUserChip({
    required this.username,
    required this.onRemove,
    super.key,
  });

  final String username;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: EdgeInsets.only(right: tagChipMarginRight),
      child: Chip(
        label: Text(
          translator.translate(
            'pages.content_editor.user',
            arguments: {'username': username},
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outlineVariant,
          ),
        ),
        deleteIcon: Assets.svg.deleteTag.render(),
        onDeleted: onRemove,
        backgroundColor: colorScheme.surfaceContainerLowest,
        deleteIconColor: colorScheme.onPrimaryContainer,
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(
          horizontal: tagChipPaddingHorizontal,
          vertical: tagChipPaddingVertical,
        ),
      ),
    );
  }
}
