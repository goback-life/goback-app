# Mentions & Tags UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle mention pickers as horizontal floating strips, render @mentions as bold clickable text in descriptions, display lockout participants as a horizontal scrollable list, and filter comment mentions to only users who can see the post.

**Architecture:** Rewrite `MentionOverlay` as a horizontal floating strip positioned above the keyboard. Extend `PostDetailDescription` to use `_parseMentions` for bold @mentions with truncation. Rewrite `PostDetailParticipants` as horizontal `SingleChildScrollView`. Remove `PostDetailTags`. Filter comment autocomplete by post visibility.

**Tech Stack:** Flutter (widgets, overlays, gestures), Riverpod providers

**Spec:** `docs/superpowers/specs/2026-04-15-mentions-and-tags-ui-design.md`

---

## File Map

### Modified files
- `lib/presentation/components/mention_text_field/mention_overlay.dart` — rewrite as horizontal floating strip above keyboard
- `lib/presentation/components/mention_text_field/mention_text_field.dart` — position overlay above keyboard, accept `filterUsers` callback
- `lib/presentation/pages/content_editor/components/content_editor_post_description.dart` — replace vertical dropdown with horizontal floating overlay
- `lib/presentation/pages/post_detail/components/post_detail_description.dart` — add bold @mention rendering with truncation
- `lib/presentation/pages/post_detail/components/post_detail_participants.dart` — rewrite as horizontal scroll
- `lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart` — remove old `PostDetailParticipants` import workaround if needed
- `lib/presentation/pages/post_detail/views/post_detail_view.dart` — replace `PostDetailTags` with `PostDetailParticipants` + bold description
- `lib/presentation/pages/post_detail/components/post_detail_overlay_input.dart` — pass visibility filter to mention autocomplete

### Removed files
- `lib/presentation/pages/post_detail/components/post_detail_tags.dart` — replaced by inline bold mentions + horizontal participants

---

## Task 1: Rewrite `MentionOverlay` as horizontal floating strip

**Files:**
- Modify: `lib/presentation/components/mention_text_field/mention_overlay.dart`
- Modify: `lib/presentation/components/mention_text_field/mention_text_field.dart`

- [ ] **Step 1: Rewrite `MentionOverlay` as horizontal strip**

Replace the current vertical `ListView` inside `AppGlassContainer` with a horizontal `SingleChildScrollView` of `@username` text items. No background, no box — just floating tappable text.

In `lib/presentation/components/mention_text_field/mention_overlay.dart`, replace the entire `MentionOverlay` class:

```dart
/// Horizontal floating strip of @username suggestions above the keyboard.
/// No background or container — just tappable text items.
class MentionOverlay extends StatelessWidget {
  const MentionOverlay({
    required this.users,
    required this.onUserSelected,
    required this.bottomInset,
    super.key,
  });

  final List<ProfileModel> users;
  final ValueChanged<ProfileModel> onUserSelected;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 8,
      child: SizedBox(
        height: 36,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: users.map((user) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => onUserSelected(user),
                  child: Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: MainColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
```

Remove the `_overlayAvatar` and `_overlayInitial` helper functions since avatars are no longer shown. Remove the `layerLink` parameter since positioning is now absolute (bottom of screen).

- [ ] **Step 2: Update `MentionTextField` overlay positioning**

In `lib/presentation/components/mention_text_field/mention_text_field.dart`:

- Remove `layerLink` and `CompositedTransformTarget` wrapper — no longer needed
- Position the overlay entry using `MediaQuery.of(context).viewInsets.bottom` for keyboard height
- Pass `bottomInset` to the new `MentionOverlay`
- Add optional `filterUsers` callback parameter for comment mention filtering

Replace the `updateOverlay` method:

```dart
    void updateOverlay() {
      final filteredUsers = getFilteredUsers();

      if (mentionQuery.value != null && filteredUsers.isNotEmpty) {
        overlayEntry.value?.remove();
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        overlayEntry.value = OverlayEntry(
          builder: (context) => MentionOverlay(
            users: filteredUsers,
            onUserSelected: selectUser,
            bottomInset: keyboardHeight,
          ),
        );
        Overlay.of(context).insert(overlayEntry.value!);
      } else {
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      }
    }
```

Remove `CompositedTransformTarget` from the return — just return the `TextField` directly.

- [ ] **Step 3: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`
Expected: No new errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/components/mention_text_field/
git commit -m "feat: rewrite mention overlay as horizontal floating strip above keyboard"
```

---

## Task 2: Update content editor mention picker

**Files:**
- Modify: `lib/presentation/pages/content_editor/components/content_editor_post_description.dart`

- [ ] **Step 1: Replace vertical dropdown with horizontal floating overlay**

In `content_editor_post_description.dart`, replace the inline mention `Container` + `ListView.builder` block (lines 106-134) with an `Overlay`-based approach that uses the new `MentionOverlay` widget.

Add overlay state management (same pattern as `MentionTextField`):

```dart
    final overlayEntry = useState<OverlayEntry?>(null);

    void updateOverlay() {
      if (mentionQuery.value != null && filteredUsers.isNotEmpty) {
        overlayEntry.value?.remove();
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        overlayEntry.value = OverlayEntry(
          builder: (_) => MentionOverlay(
            users: filteredUsers,
            onUserSelected: (user) {
              onMentionSelected(user);
              overlayEntry.value?.remove();
              overlayEntry.value = null;
            },
            bottomInset: keyboardHeight,
          ),
        );
        Overlay.of(context).insert(overlayEntry.value!);
      } else {
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      }
    }
```

Add `useEffect` to update overlay when `mentionQuery` or `filteredUsers` change, and clean up on dispose.

Remove the inline `Container` + `ListView.builder` from the `Column` children — the overlay handles it now.

- [ ] **Step 2: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/content_editor/components/content_editor_post_description.dart
git commit -m "feat: use horizontal floating mention overlay in content editor"
```

---

## Task 3: Add bold @mentions to `PostDetailDescription`

**Files:**
- Modify: `lib/presentation/pages/post_detail/components/post_detail_description.dart`

- [ ] **Step 1: Add mention parsing and bold rendering**

The overlay content (`post_detail_overlay_content.dart`) already has a `_parseMentions` helper at line 57. Extract this into a shared utility or duplicate it in `PostDetailDescription` (it's 28 lines, small enough to inline).

In `post_detail_description.dart`, replace the plain `Text` widget (line 73) and `LinkableText` (line 41) with `RichText` using `_parseMentions`:

For the non-text-post path (the truncatable description), replace:
```dart
            AnimatedDefaultTextStyle(
              ...
              child: Text(
                description,
                maxLines: ...,
                overflow: ...,
              ),
            ),
```

With:
```dart
            RichText(
              text: _parseMentions(
                description,
                textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outlineVariant,
                  height: 20.5 / 14.0,
                ) ?? const TextStyle(),
                onMentionTap: onMentionTap,
              ),
              maxLines: showFullText.value
                  ? null
                  : (isLongText.value ? descriptionMaxLines.toInt() : null),
              overflow: showFullText.value ? null : TextOverflow.ellipsis,
            ),
```

For the text-post path (currently `LinkableText`), replace with `RichText` + `_parseMentions` as well. URLs can be handled by combining both parsers or by adding URL detection to `_parseMentions`.

Add a new callback parameter to the widget:
```dart
  final void Function(String username)? onMentionTap;
```

- [ ] **Step 2: Add the `_parseMentions` helper to the file**

Copy the helper from `post_detail_overlay_content.dart` (lines 57-85) into this file as a top-level function. Or better: create a shared utility file.

Create `lib/presentation/utilities/mention_text_parser.dart`:

```dart
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
```

Update `post_detail_overlay_content.dart` to import and use this shared function instead of its local `_parseMentions`.

- [ ] **Step 3: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/utilities/mention_text_parser.dart \
  lib/presentation/pages/post_detail/components/post_detail_description.dart \
  lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart
git commit -m "feat: render @mentions as bold clickable text in post descriptions"
```

---

## Task 4: Rewrite `PostDetailParticipants` as horizontal scroll

**Files:**
- Modify: `lib/presentation/pages/post_detail/components/post_detail_participants.dart`

- [ ] **Step 1: Replace Wrap layout with horizontal SingleChildScrollView**

Rewrite the widget to use a `SingleChildScrollView(scrollDirection: Axis.horizontal)` with a `Row` of participant items. Remove the tag icon (`Assets.svg.tag.render()`). Remove the `PostDetailLayout` and `MainLayout` mixins if no longer needed.

```dart
import 'package:cloudless/core/features/lockout/domain/utilities/participant_distance.dart';
import 'package:flutter/material.dart';

class PostDetailParticipants extends StatelessWidget {
  const PostDetailParticipants({
    required this.participantIds,
    required this.participantUsernames,
    required this.participantAvatars,
    required this.participantJoinedVia,
    required this.myFriendIds,
    this.onFriendTap,
    this.onFriendOfFriendTap,
    this.textStyle,
    this.labelStyle,
    this.collapsedStyle,
    super.key,
  });

  final List<String> participantIds;
  final List<String> participantUsernames;
  final List<String?> participantAvatars;
  final List<String?> participantJoinedVia;
  final Set<String> myFriendIds;
  final void Function(String userId, String username)? onFriendTap;
  final void Function(String userId, String username, String? lockoutId)? onFriendOfFriendTap;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? collapsedStyle;

  @override
  Widget build(BuildContext context) {
    if (participantIds.isEmpty) return const SizedBox.shrink();

    final defaultStyle = textStyle ?? const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: Colors.white,
    );
    final defaultLabel = labelStyle ?? defaultStyle.copyWith(
      fontWeight: FontWeight.w400,
      color: Colors.white.withValues(alpha: 0.6),
    );
    final defaultCollapsed = collapsedStyle ?? defaultStyle.copyWith(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: Colors.white.withValues(alpha: 0.5),
    );

    final d1 = <int>[];
    final d2 = <int>[];
    var d3Count = 0;

    for (var i = 0; i < participantIds.length; i++) {
      final d = ParticipantDistance.compute(
        participantId: participantIds[i],
        joinedVia: i < participantJoinedVia.length ? participantJoinedVia[i] : null,
        myFriendIds: myFriendIds,
      );
      if (d == 1) d1.add(i);
      else if (d == 2) d2.add(i);
      else d3Count++;
    }

    final items = <Widget>[];

    for (final i in d1) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      items.add(GestureDetector(
        onTap: () => onFriendTap?.call(participantIds[i], participantUsernames[i]),
        child: Text('@${participantUsernames[i]}', style: defaultStyle),
      ));
    }

    for (final i in d2) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      final jvId = participantJoinedVia[i];
      String? jvName;
      if (jvId != null) {
        final idx = participantIds.indexOf(jvId);
        if (idx >= 0) jvName = participantUsernames[idx];
      }
      items.add(GestureDetector(
        onTap: () => onFriendOfFriendTap?.call(participantIds[i], participantUsernames[i], null),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '@${participantUsernames[i]}', style: defaultStyle),
          if (jvName != null) TextSpan(text: ' · via @$jvName', style: defaultLabel),
        ])),
      ));
    }

    if (d3Count > 0) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      items.add(Text('and $d3Count other${d3Count == 1 ? '' : 's'}', style: defaultCollapsed));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}
```

- [ ] **Step 2: Update callers**

In `post_detail_overlay_content.dart`, update the `PostDetailParticipants` call — remove `onFriendOfFriendTap`'s unused `lockoutId` parameter if the widget signature changed, and pass appropriate styles scaled with `scale`.

- [ ] **Step 3: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/post_detail/components/post_detail_participants.dart \
  lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart
git commit -m "feat: rewrite lockout participants as horizontal scrollable list"
```

---

## Task 5: Remove `PostDetailTags` and update `PostDetailView`

**Files:**
- Delete: `lib/presentation/pages/post_detail/components/post_detail_tags.dart`
- Modify: `lib/presentation/pages/post_detail/views/post_detail_view.dart`

- [ ] **Step 1: Remove PostDetailTags usage from PostDetailView**

In `post_detail_view.dart`, find the `PostDetailTags` block (around lines 341-353):

```dart
                    if (post.taggedUsernames.isNotEmpty) ...[
                      PostDetailTags(
                        taggedUsernames: post.taggedUsernames,
                        taggedUserIds: post.taggedUserIds,
                        onUserTap: (userId, username) =>
                            PostDetailNavigation.navigateToUserProfile(
                              ref,
                              userId,
                              username,
                            ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
```

Replace with `PostDetailParticipants` for lockout posts:

```dart
                    if (post.isLockoutPost && post.lockoutParticipantIds.isNotEmpty) ...[
                      PostDetailParticipants(
                        participantIds: post.lockoutParticipantIds,
                        participantUsernames: post.lockoutParticipantUsernames,
                        participantAvatars: post.lockoutParticipantAvatars,
                        participantJoinedVia: post.lockoutParticipantJoinedVia,
                        myFriendIds: myFriendIds,
                        onFriendTap: (userId, username) =>
                            PostDetailNavigation.navigateToUserProfile(ref, userId, username),
                        onFriendOfFriendTap: (userId, username, _) =>
                            PostDetailNavigation.navigateToUserProfile(ref, userId, username),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
```

You'll need to add `myFriendIds` computation to `PostDetailView` — use the same pattern as `PostDetailOverlayContent`: watch `useMentionAutocomplete` and derive `myFriendIds` from `allUsers`.

- [ ] **Step 2: Update PostDetailDescription usage in PostDetailView**

Find where `PostDetailDescription` is used in `post_detail_view.dart` and pass the `onMentionTap` callback:

```dart
PostDetailDescription(
  description: post.description ?? '',
  contentType: post.contentType,
  onMentionTap: (username) {
    final user = allUsers.where((u) => u.username == username).firstOrNull;
    if (user != null) {
      PostDetailNavigation.navigateToUserProfile(ref, user.id, user.username);
    }
  },
),
```

- [ ] **Step 3: Delete `post_detail_tags.dart`**

Remove the file entirely.

- [ ] **Step 4: Remove any remaining imports of `PostDetailTags`**

Search for and remove any import of `post_detail_tags.dart` across the codebase.

- [ ] **Step 5: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 6: Commit**

```bash
git rm lib/presentation/pages/post_detail/components/post_detail_tags.dart
git add lib/presentation/pages/post_detail/views/post_detail_view.dart
git commit -m "feat: replace PostDetailTags with horizontal participants, add bold mentions to calendar post detail"
```

---

## Task 6: Filter comment mention autocomplete by post visibility

**Files:**
- Modify: `lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart`
- Modify: `lib/presentation/pages/post_detail/components/post_detail_overlay_input.dart`
- Modify: `lib/presentation/components/mention_text_field/mention_text_field.dart`

- [ ] **Step 1: Add `filterUsers` parameter to `MentionTextField`**

In `mention_text_field.dart`, add an optional filter:

```dart
  /// Optional filter applied to allUsers before showing suggestions.
  /// Used to restrict comment mentions to users who can see the post.
  final bool Function(ProfileModel)? userFilter;
```

In `getFilteredUsers()`, apply the filter:

```dart
    List<ProfileModel> getFilteredUsers() {
      final query = mentionQuery.value;
      if (query == null) return [];

      final lowerQuery = query.toLowerCase();
      var candidates = allUsers.where(
        (u) => u.username.toLowerCase().startsWith(lowerQuery),
      );
      if (userFilter != null) {
        candidates = candidates.where(userFilter!);
      }
      return candidates.take(5).toList();
    }
```

- [ ] **Step 2: Pass visibility filter from overlay content to comment input**

In `post_detail_overlay_content.dart`, compute the set of users who can see the post:

```dart
    final canSeePostIds = useMemoized(() {
      final ids = <String>{post.authorId, ...myFriendIds};
      if (post.isLockoutPost) {
        ids.addAll(post.lockoutParticipantIds);
      }
      return ids;
    }, [post.authorId, myFriendIds, post.lockoutParticipantIds]);
```

Note: `myFriendIds` here represents the viewer's friends. But we need friends of the *author* to determine who can see the post. Since the viewer is viewing the post, and the autocomplete already filters to `allUsers` (the viewer's circle), the filter is: `myCircle ∩ canSeePost`.

For simplicity, the viewer's circle members who are also friends of the author OR lockout participants are mentionable. Since we don't have the author's friend list client-side, and the viewer can see the post (so they're either the author's friend or a lockout participant), we approximate:

```dart
    // For the post author's own posts: all viewer's circle can see it (they're friends with author)
    // For cross-circle lockout posts: only lockout participants can see it
    final commentMentionFilter = useMemoized(() {
      if (!post.isLockoutPost || post.isAuthorConnected) {
        // Author is viewer's friend — all viewer's friends who are also author's friends can see it
        // Since we don't have author's friend list, don't filter (RPC will reject invalid mentions)
        return null;
      }
      // Cross-circle post — only lockout participants can see it
      final participantIds = {post.authorId, ...post.lockoutParticipantIds};
      return (ProfileModel u) => participantIds.contains(u.id);
    }, [post.isAuthorConnected, post.lockoutParticipantIds]);
```

Pass to `PostDetailOverlayInput`:

```dart
PostDetailOverlayInput(
  ...
  allUsers: allUsers,
  userFilter: commentMentionFilter,
  ...
)
```

- [ ] **Step 3: Pass filter through `PostDetailOverlayInput` to `MentionTextField`**

In `post_detail_overlay_input.dart`, add `userFilter` parameter and forward to `MentionTextField`:

```dart
  final bool Function(ProfileModel)? userFilter;
```

- [ ] **Step 4: Verify compilation**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/components/mention_text_field/mention_text_field.dart \
  lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart \
  lib/presentation/pages/post_detail/components/post_detail_overlay_input.dart
git commit -m "feat: filter comment mention autocomplete to users who can see the post"
```
