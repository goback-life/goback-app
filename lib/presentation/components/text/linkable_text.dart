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

    // Regex pattern to match URLs
    // Matches: http://, https://, and www. URLs
    final urlPattern = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+)',
      caseSensitive: false,
    );

    // Memoize the spans creation to avoid recreating recognizers on every build
    final spans = useMemoized(() {
      final result = <TextSpan>[];
      int lastMatchEnd = 0;

      for (final match in urlPattern.allMatches(text)) {
        // Add text before the URL
        if (match.start > lastMatchEnd) {
          result.add(TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: defaultStyle,
          ));
        }

        // Add the URL as a clickable span
        final url = match.group(0)!;
        // Ensure URL has protocol for parsing
        final urlWithProtocol = url.startsWith('http://') || url.startsWith('https://')
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
                  // Fallback: try launching without canLaunchUrl check
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            } catch (e) {
              // Silently fail if URL can't be launched
            }
          };
        
        result.add(TextSpan(
          text: url,
          style: linkStyle,
          recognizer: recognizer,
        ));

        lastMatchEnd = match.end;
      }

      // Add remaining text after the last URL
      if (lastMatchEnd < text.length) {
        result.add(TextSpan(
          text: text.substring(lastMatchEnd),
          style: defaultStyle,
        ));
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

