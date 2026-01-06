import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that renders text with clickable URLs.
/// 
/// Automatically detects URLs in the text and makes them clickable.
/// URLs are styled with blue color and underline.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final linkStyle = defaultStyle.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    // Regex pattern to match URLs
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in urlPattern.allMatches(text)) {
      // Add text before the URL
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add the URL as a clickable span
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

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
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

