import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that renders text with clickable URLs and markdown links.
///
/// Automatically detects:
/// - Markdown links [alias](url) - renders as clickable alias text
/// - Regular URLs - renders as clickable links
class LinkableText extends HookWidget {
  const LinkableText({
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  // Helper function to add text span
  static void _addTextSpan(
    List<TextSpan> spans,
    String text,
    int start,
    int end,
    TextStyle style,
  ) {
    if (start < end && end <= text.length) {
      final textSegment = text.substring(start, end);
      if (textSegment.isNotEmpty) {
        spans.add(TextSpan(text: textSegment, style: style));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle =
        style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    // Use tertiary color (blue) for links since primary is white
    final linkColor = colorScheme.tertiary;
    // Create link style that ensures text is visible and clickable
    final linkStyle = TextStyle(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
      fontSize: defaultStyle.fontSize,
      fontWeight: defaultStyle.fontWeight,
      fontFamily: defaultStyle.fontFamily,
      height: defaultStyle.height,
      letterSpacing: defaultStyle.letterSpacing,
    );

    // Memoize the spans creation to avoid recreating recognizers on every build
    // Priority: Markdown links > Regular URLs
    final spans = useMemoized(() {
      final result = <TextSpan>[];

      // Track which parts of text are already processed
      final processedRanges = <({int start, int end})>[];

      // First, process markdown links [alias](url)
      final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

      for (final match in markdownLinkPattern.allMatches(text)) {
        final alias = match.group(1)!;
        final url = match.group(2)!;
        final start = match.start;
        final end = match.end;

        // Add text before this markdown link
        if (start > 0) {
          final lastEnd = processedRanges.isEmpty
              ? 0
              : processedRanges.last.end;
          if (start > lastEnd) {
            _addTextSpan(result, text, lastEnd, start, defaultStyle);
          }
        }

        // Add the markdown link as clickable alias
        final urlWithProtocol =
            url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';

        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            try {
              final uri = Uri.tryParse(urlWithProtocol);
              if (uri != null) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            } catch (e) {
              // Silently fail if URL can't be launched
            }
          };

        result.add(
          TextSpan(text: alias, style: linkStyle, recognizer: recognizer),
        );

        processedRanges.add((start: start, end: end));
      }

      // Then, process regular URLs (but skip if inside markdown links)
      final urlPattern = RegExp(
        r'(https?://[^\s]+|www\.[^\s]+)',
        caseSensitive: false,
      );

      for (final match in urlPattern.allMatches(text)) {
        final start = match.start;
        final end = match.end;

        // Check if this URL is inside a processed range
        final isInProcessedRange = processedRanges.any(
          (range) => start >= range.start && end <= range.end,
        );

        if (isInProcessedRange) continue;

        // Add text before this URL
        final lastEnd = processedRanges.isEmpty
            ? 0
            : processedRanges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
        if (start > lastEnd) {
          _addTextSpan(result, text, lastEnd, start, defaultStyle);
        }

        // Add the URL as a clickable span
        final url = match.group(0)!;
        final urlWithProtocol =
            url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';

        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            try {
              final uri = Uri.tryParse(urlWithProtocol);
              if (uri != null) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            } catch (e) {
              // Silently fail if URL can't be launched
            }
          };

        result.add(
          TextSpan(text: url, style: linkStyle, recognizer: recognizer),
        );

        processedRanges.add((start: start, end: end));
      }

      // Add remaining text
      final lastEnd = processedRanges.isEmpty
          ? 0
          : processedRanges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
      if (lastEnd < text.length) {
        _addTextSpan(result, text, lastEnd, text.length, defaultStyle);
      }

      return result;
    }, [text, defaultStyle, linkStyle]);

    // Dispose recognizers when widget is disposed
    useEffect(() {
      return () {
        for (final span in spans) {
          span.recognizer?.dispose();
        }
      };
    }, [spans]);

    // If no URLs were found, return plain text
    if (spans.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle, // Parent style for inheritance
        children: spans,
      ),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
