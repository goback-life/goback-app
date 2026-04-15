import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Parses text for @username patterns and wraps them in bold spans.
/// When [onMentionTap] is provided, each @mention becomes tappable.
TextSpan parseMentions(
  String text,
  TextStyle base, {
  void Function(String username)? onMentionTap,
}) {
  final regex = RegExp(r'@(\w+)');
  final children = <InlineSpan>[];
  var lastEnd = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > lastEnd) {
      children.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    final username = match.group(1)!;
    children.add(
      TextSpan(
        text: match.group(0),
        style: base.copyWith(fontWeight: FontWeight.w700),
        recognizer: onMentionTap != null
            ? (TapGestureRecognizer()..onTap = () => onMentionTap(username))
            : null,
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    children.add(TextSpan(text: text.substring(lastEnd)));
  }
  return TextSpan(style: base, children: children);
}
