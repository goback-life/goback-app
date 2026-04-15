# Mentions & Tags UI Redesign

**Date:** 2026-04-15
**Status:** Draft — pending user review
**Depends on:** `2026-04-15-cross-circle-tagging-design.md` (lockout_participants table, distance tiers)

## Problem

Three UI gaps in the tagging system:

1. The mention picker in the post editor uses a vertical dropdown below the text field. Should be Instagram-style: horizontal scrollable `@username` text floating above the keyboard.
2. @mentions in post descriptions render as plain text. Should be bold and clickable, navigating to the user's profile.
3. Lockout participants are displayed as a vertical Wrap with a tag icon. Should be a horizontal scrollable list of bold names with distance labels under the description.

Additionally, comment mention autocomplete currently shows all circle members, even those who can't see the post. Must be filtered to only show users who can see the post.

## 1. Mention Picker in Content Editor

### Post Description

**Current:** `ContentEditorPostDescription` shows a vertical `ListView` dropdown below the text field when typing `@`.

**New:** Horizontal scrollable strip of `@username` text, floating above the keyboard. No background, no box — just tappable text.

**Implementation:**
- Remove the inline `Container` + `ListView.builder` mention dropdown from `ContentEditorPostDescription`
- Add an `Overlay` entry positioned at `bottom: MediaQuery.of(context).viewInsets.bottom` (keyboard height)
- Renders a `SingleChildScrollView(scrollDirection: Axis.horizontal)` with `@username` `GestureDetector` text items spaced horizontally
- Same mention detection logic: `detectMention`, `filterMentionUsers`, `insertMention` from `mention_helpers.dart`
- Same circle-only filtering (uses `allUsers` which is already circle members)
- Dismiss overlay when mention query is null or user taps a suggestion

### Comment Input

**Current:** `MentionTextField` (used in `post_detail_overlay_input.dart` and `post_detail_comment_input.dart`) shows a vertical `MentionOverlay` dropdown.

**New:** Same horizontal floating strip as the post editor. Consistent style across the app.

**Comment mention restriction:** Autocomplete only shows users who can see the post:

```dart
autocompleteUsers = myCircle.where((user) =>
  friendsOfAuthor.contains(user.id) ||
  lockoutParticipantIds.contains(user.id)
)
```

This is a client-side filter on top of the existing circle members list. The `add_comment_mentions` RPC friendship check stays as a backend safeguard.

## 2. Bold Clickable @mentions in Description Display

**Current:** `LinkableText` renders URLs as clickable but treats `@username` as plain text.

**New:** Extend to also detect `@username` patterns and render them bold + clickable.

**Detection:** Regex `@(\w+)`. Only bold usernames that match the post's `taggedUsernames` list — prevents bolding random `@` text that isn't an actual tag.

**Rendering:** `TextSpan` with `fontWeight: FontWeight.bold` and a `TapGestureRecognizer`. Navigation on tap:
- User is in viewer's circle → full profile (`CircleProfileRoutable`)
- User is distance 2 via lockout → limited profile (`LimitedProfileView`)
- Otherwise → no action (defensive; mentions are circle-only)

**Truncation:** Description shows 3-4 lines with "more" tap to expand (Instagram-style). Uses `maxLines: 4` + `TextOverflow.ellipsis` with a `GestureDetector` to toggle expanded state.

**Applied in both post detail views:**
- `PostDetailOverlayContent` — feed → post detail path (via `PostDetailOverlay`)
- `PostDetailView` — calendar → post detail path

## 3. Lockout Participant Horizontal List

**Current:** `PostDetailParticipants` renders a vertical `Wrap` layout with a tag icon, showing tiered `@username` text.

**New:** Horizontal `SingleChildScrollView` under the description. No tag icon. Bold `@username` text with distance labels.

**Layout:**
```
[description with bold @mentions, 3-4 lines, "more" to expand]

@alice, @bob · via @alice, and 2 others  →  (scrolls horizontally)
```

**Items in order:**
1. Distance 1 (friends): **`@username`** — bold, tappable → full profile
2. Distance 2 (friend of friend): **`@username`** `· via @X` — bold name + lighter label, tappable → limited profile
3. Distance 3+: `and N others` — not tappable, lighter text

**Separators:** Comma + space between items. No comma before "and N others".

**Excludes the post author** — they're already shown as the author above.

**Applied in both post detail views:**
- `PostDetailOverlayContent` — replaces current `PostDetailParticipants`
- `PostDetailView` — replaces current `PostDetailTags`

**Removed:** `PostDetailTags` widget and all usages. `PostDetailParticipants` rewritten with horizontal scroll.

## 4. Comment Mention Filtering

Comment mention autocomplete only shows users who can actually see the post. This prevents the scenario where B tags C in a comment on A's post, but C can't see A's post.

**Filter logic:**
```dart
// Users the commenter can mention = their circle ∩ users who can see the post
final canSeePost = {...friendsOfAuthor, ...lockoutParticipantIds, authorId};
final mentionableUsers = myCircle.where((u) => canSeePost.contains(u.id));
```

**No backend changes needed** — `add_comment_mentions` RPC already checks friendship. The filtering is client-side in the autocomplete suggestions.

## Files Affected

### Modified
- `lib/presentation/pages/content_editor/components/content_editor_post_description.dart` — replace vertical dropdown with horizontal floating overlay
- `lib/presentation/components/mention_text_field/mention_text_field.dart` — replace `MentionOverlay` with horizontal floating strip
- `lib/presentation/components/mention_text_field/mention_overlay.dart` — rewrite as horizontal layout or replace entirely
- `lib/presentation/components/text/linkable_text.dart` — add `@username` detection, bold rendering, tap navigation
- `lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart` — use new description + participant widgets
- `lib/presentation/pages/post_detail/views/post_detail_view.dart` — replace `PostDetailTags` with new participant list
- `lib/presentation/pages/post_detail/components/post_detail_participants.dart` — rewrite as horizontal scroll
- `lib/presentation/pages/post_detail/components/post_detail_description.dart` — add truncation with "more" toggle

### Removed
- `lib/presentation/pages/post_detail/components/post_detail_tags.dart` — no longer needed; mentions are inline, participants are horizontal list

## Design Decisions Reference

| # | Question | Decision |
|---|----------|----------|
| 1 | Where should description + tags be visible? | Post detail only (C) — feed cards stay clean |
| 2 | Mention picker position | Floating above keyboard, overlaying content (C) |
| 3 | Mention suggestion format | Username only — just `@username` tappable text (B) |
| 4 | Tapping a bold @mention | Navigate to profile with distance-based logic (A) |
| 5 | Lockout participant list format | Bold `@username` with distance labels in horizontal scroll (C) |
| 6 | PostDetailTags widget | Remove entirely — mentions inline, participants horizontal (A) |
| 7 | Which post detail view | Both — `PostDetailOverlay` (feed path) and `PostDetailView` (calendar path) updated |
| 8 | Comment mention autocomplete | Same horizontal floating style (A) |
| 9 | Description truncation | 3-4 lines with "more" to expand (B) |
| 10 | Lockout participant list includes author? | No — just other participants (A) |
| 11 | Comment mentions — can B tag C on A's post if C can't see it? | No — autocomplete filtered to users who can see the post (A) |
