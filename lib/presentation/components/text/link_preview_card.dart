import 'package:cloudless/core/features/post/domain/models/link_preview_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display link preview cards (like Twitter/X).
///
/// **Future Implementation:**
/// This is a placeholder structure for future link preview functionality.
/// When link preview fetching is implemented, this component will display
/// preview cards with image, title, description, and site name.
class LinkPreviewCard extends HookWidget {
  const LinkPreviewCard({required this.linkPreview, super.key});

  final LinkPreviewModel linkPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Placeholder implementation - will be fully implemented when
    // link preview fetching is added
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(linkPreview.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (linkPreview.title != null)
              Text(
                linkPreview.title!,
                style: textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (linkPreview.description != null) ...[
              const SizedBox(height: 4),
              Text(
                linkPreview.description!,
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (linkPreview.siteName != null) ...[
              const SizedBox(height: 4),
              Text(
                linkPreview.siteName!,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
