import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/mention_text_field/mention_overlay.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// A text field that supports @mention autocomplete from circle members.
/// Shows a horizontal strip of matching users when the user types @.
class MentionTextField extends HookWidget with MainLayout {
  const MentionTextField({
    required this.controller,
    required this.allUsers,
    required this.onMentionsChanged,
    this.decoration,
    this.style,
    this.maxLines,
    this.maxLength,
    this.hintText,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.userFilter,
    super.key,
  });

  final TextEditingController controller;
  final List<ProfileModel> allUsers;
  final ValueChanged<List<String>> onMentionsChanged;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? maxLength;
  final String? hintText;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool Function(ProfileModel)? userFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final overlayEntry = useState<OverlayEntry?>(null);
    final mentionQuery = useState<String?>(null);
    final mentionStartIndex = useState<int?>(null);
    final collectedMentions = useState<List<String>>([]);

    /// Parses the current text to find any @mention being typed.
    void updateMentionState() {
      final text = controller.text;
      final selection = controller.selection;

      if (!selection.isValid ||
          selection.baseOffset != selection.extentOffset) {
        mentionQuery.value = null;
        mentionStartIndex.value = null;
        return;
      }

      final cursorPos = selection.baseOffset;
      if (cursorPos == 0) {
        mentionQuery.value = null;
        mentionStartIndex.value = null;
        return;
      }

      // Look backwards from cursor to find @
      int atIndex = -1;
      for (int i = cursorPos - 1; i >= 0; i--) {
        final char = text[i];
        if (char == '@') {
          atIndex = i;
          break;
        }
        // Stop at space or newline - @ must be at word start
        if (char == ' ' || char == '\n') break;
      }

      if (atIndex == -1) {
        mentionQuery.value = null;
        mentionStartIndex.value = null;
        return;
      }

      // Check @ is at start or after space/newline
      if (atIndex > 0) {
        final prevChar = text[atIndex - 1];
        if (prevChar != ' ' && prevChar != '\n') {
          mentionQuery.value = null;
          mentionStartIndex.value = null;
          return;
        }
      }

      // Extract the query after @
      final query = text.substring(atIndex + 1, cursorPos);
      if (query.contains(' ') || query.contains('\n')) {
        mentionQuery.value = null;
        mentionStartIndex.value = null;
        return;
      }

      mentionQuery.value = query;
      mentionStartIndex.value = atIndex;
    }

    /// Filters users based on the current mention query.
    List<ProfileModel> getFilteredUsers() {
      final query = mentionQuery.value;
      if (query == null) return [];

      final lowerQuery = query.toLowerCase();
      var filtered = allUsers.where(
        (u) => u.username.toLowerCase().startsWith(lowerQuery),
      );

      if (userFilter != null) {
        filtered = filtered.where(userFilter!);
      }

      return filtered.take(5).toList();
    }

    /// Inserts the selected username at the mention position.
    void selectUser(ProfileModel user) {
      final startIdx = mentionStartIndex.value;
      if (startIdx == null) return;

      final text = controller.text;
      final cursorPos = controller.selection.baseOffset;

      // Replace @query with @username
      final newText =
          text.substring(0, startIdx) +
          '@${user.username} ' +
          text.substring(cursorPos);

      controller.text = newText;
      final newCursorPos =
          startIdx + user.username.length + 2; // @ + username + space
      controller.selection = TextSelection.collapsed(offset: newCursorPos);

      // Track the mention
      if (!collectedMentions.value.contains(user.id)) {
        collectedMentions.value = [...collectedMentions.value, user.id];
        onMentionsChanged(collectedMentions.value);
      }

      // Clear mention state
      mentionQuery.value = null;
      mentionStartIndex.value = null;
    }

    /// Shows/hides the overlay based on mention state.
    void updateOverlay() {
      final filteredUsers = getFilteredUsers();

      if (mentionQuery.value != null && filteredUsers.isNotEmpty) {
        overlayEntry.value?.remove();
        final currentUsers = List<ProfileModel>.from(filteredUsers);
        overlayEntry.value = OverlayEntry(
          builder: (overlayContext) {
            final bottomInset = MediaQuery.of(overlayContext).viewInsets.bottom;
            return MentionOverlay(
              bottomInset: bottomInset,
              users: currentUsers,
              onUserSelected: selectUser,
            );
          },
        );
        Overlay.of(context).insert(overlayEntry.value!);
      } else {
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      }
    }

    useEffect(() {
      void listener() {
        updateMentionState();
        updateOverlay();
      }

      controller.addListener(listener);
      return () {
        controller.removeListener(listener);
        overlayEntry.value?.remove();
      };
    }, [controller, allUsers]);

    // Clean up overlay on dispose
    useEffect(() {
      return () {
        overlayEntry.value?.remove();
      };
    }, []);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: style ?? textTheme.bodyMedium,
      cursorColor: colorScheme.tertiary,
      decoration:
          decoration ??
          InputDecoration(
            hintText: hintText ?? 'Type @ to mention someone...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
    );
  }
}
