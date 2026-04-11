import 'package:flutter/services.dart';

/// TextInputFormatter that prevents backspace from deleting individual characters
/// within a markdown link [alias](url). Instead, it deletes the entire markdown link.
class MarkdownLinkFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if this is a deletion (backspace or delete)
    if (newValue.text.length < oldValue.text.length) {
      final deletedLength = oldValue.text.length - newValue.text.length;
      final oldSelection = oldValue.selection;
      final newSelection = newValue.selection;

      // Only handle single character deletions (backspace/delete)
      if (deletedLength == 1 &&
          oldSelection.isCollapsed &&
          newSelection.isCollapsed) {
        // Get cursor positions
        final oldCursorPosition = oldSelection.baseOffset;
        final newCursorPosition = newSelection.baseOffset;

        // Determine which character was deleted
        // For backspace: oldCursorPosition > newCursorPosition (cursor moved left)
        // For delete: oldCursorPosition == newCursorPosition (cursor stayed same)
        final deletedCharPosition = oldCursorPosition > newCursorPosition
            ? newCursorPosition // Backspace: deleted char is at new cursor position
            : oldCursorPosition; // Delete: deleted char is at old cursor position

        // Find markdown links in the old text
        final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
        final matches = markdownLinkPattern.allMatches(oldValue.text);

        for (final match in matches) {
          final linkStart = match.start;
          final linkEnd = match.end;

          // Check if the deleted character position is inside this markdown link
          final isInsideLink =
              deletedCharPosition >= linkStart && deletedCharPosition < linkEnd;

          if (isInsideLink) {
            // Delete the entire markdown link
            final beforeLink = oldValue.text.substring(0, linkStart);
            final afterLink = oldValue.text.substring(linkEnd);
            final newText = beforeLink + afterLink;

            // Calculate new cursor position (at the start of where the link was)
            final finalCursorPosition = linkStart.clamp(0, newText.length);

            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: finalCursorPosition),
            );
          }
        }
      }
    }

    return newValue;
  }
}
