import 'package:cloudless/core/models/profile_model.dart';
import 'package:flutter/widgets.dart';

/// Shared helpers for @mention detection, filtering, and insertion
/// used by ContentEditorTextPost and ContentEditorPostDescription.

/// Detects an active @mention being typed before [cursorPosition] in [text].
/// Returns `null` for both fields if no active mention is found.
({String? query, int? startIndex}) detectMention(
  String text,
  int cursorPosition,
) {
  final textBeforeCursor = text.substring(0, cursorPosition);
  final lastAtIndex = textBeforeCursor.lastIndexOf('@');

  if (lastAtIndex == -1) return (query: null, startIndex: null);

  final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
  if (textAfterAt.contains(' ')) return (query: null, startIndex: null);

  return (query: textAfterAt.toLowerCase(), startIndex: lastAtIndex);
}

/// Filters [allUsers] by [query], returning up to 10 matching users.
List<ProfileModel> filterMentionUsers(
  String? query,
  List<ProfileModel> allUsers,
) {
  if (query == null) return const [];
  if (query.isEmpty) return allUsers.take(10).toList();

  return allUsers
      .where((user) => user.username.toLowerCase().startsWith(query))
      .take(10)
      .toList();
}

/// Inserts [user]'s username at [mentionStartIndex] in [controller],
/// replacing the partial @query text. Returns the new text value.
String insertMention({
  required TextEditingController controller,
  required ProfileModel user,
  required int mentionStartIndex,
}) {
  final text = controller.text;
  final cursorPos = controller.selection.baseOffset;
  final textAfterAt = text.substring(mentionStartIndex + 1, cursorPos);
  final end = mentionStartIndex + 1 + textAfterAt.length;

  final newText = text.replaceRange(
    mentionStartIndex,
    end,
    '@${user.username} ',
  );
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(
      offset: mentionStartIndex + user.username.length + 2,
    ),
  );

  return newText;
}
