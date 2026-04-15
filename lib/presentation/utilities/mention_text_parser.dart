import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Parses text for @username patterns and wraps matched tags in bold spans.
/// Only usernames present in [taggedUsernames] are bolded and made tappable.
/// If [taggedUsernames] is null, all @username patterns are bolded (legacy).
/// When [onMentionTap] is provided, each matched @mention becomes tappable.
TextSpan parseMentions(
  String text,
  TextStyle base, {
  Set<String>? taggedUsernames,
  void Function(String username)? onMentionTap,
}) {
  final regex = RegExp(r'@(\w+)');
  final children = <InlineSpan>[];
  var lastEnd = 0;
  for (final match in regex.allMatches(text)) {
    final username = match.group(1)!;
    final isTagged =
        taggedUsernames == null ||
        taggedUsernames.contains(username.toLowerCase());

    if (match.start > lastEnd) {
      children.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }

    if (isTagged) {
      children.add(
        TextSpan(
          text: match.group(0),
          style: base.copyWith(fontWeight: FontWeight.w700),
          recognizer: onMentionTap != null
              ? (TapGestureRecognizer()..onTap = () => onMentionTap(username))
              : null,
        ),
      );
    } else {
      // Not a real tag — render as plain text
      children.add(TextSpan(text: match.group(0)));
    }
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    children.add(TextSpan(text: text.substring(lastEnd)));
  }
  return TextSpan(style: base, children: children);
}
