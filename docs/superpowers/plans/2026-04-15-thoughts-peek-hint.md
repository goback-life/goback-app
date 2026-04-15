# Thoughts Peek Hint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Subtly hint to users that replies exist by showing a count on the "Thoughts" header and auto-scrolling to peek it into view when the post detail overlay opens.

**Architecture:** Two changes to existing files — (1) make the "Thoughts" header count-aware via `commentCount` on `FeedPostModel`, (2) add a delayed `animateTo` in the overlay so the header peeks into the visible content area when comments exist. No new files, no new widgets.

**Tech Stack:** Flutter, flutter_hooks (`useEffect`), existing `ScrollController`

---

### Task 1: Count-aware "Thoughts" header

**Files:**
- Modify: `lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart:342-355` (`_buildThoughtsHeader`)
- Modify: `lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart:221` (call site)

- [ ] **Step 1: Update `_buildThoughtsHeader` to accept `commentCount` and render count-first label**

Change the method signature and body at line 342:

```dart
Widget _buildThoughtsHeader(int commentCount) {
  final fs = 24.0 * scale;
  final ls = -1.44 * scale;
  final label = commentCount > 0
      ? '$commentCount ${commentCount == 1 ? 'Thought' : 'Thoughts'}'
      : 'Thoughts';
  return Text(
    label,
    style: TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w500,
      fontSize: fs,
      color: MainColors.white,
      letterSpacing: ls,
    ),
  );
}
```

- [ ] **Step 2: Pass `commentCount` at the call site**

At line 221 in the `ListView` children, change:

```dart
_buildThoughtsHeader(),
```

to:

```dart
_buildThoughtsHeader(post.commentCount),
```

- [ ] **Step 3: Hot-restart and verify**

Open a post with comments → confirm header reads "3 Thoughts" (or whatever count).
Open a post with zero comments → confirm header reads "Thoughts".
Open a post with exactly 1 comment → confirm header reads "1 Thought".

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/post_detail/components/post_detail_overlay_content.dart
git commit -m "feat: show comment count on Thoughts header"
```

---

### Task 2: Auto-peek scroll on card open

**Files:**
- Modify: `lib/presentation/pages/post_detail/views/post_detail_overlay.dart:87-105` (add peek effect)

- [ ] **Step 1: Add a peek scroll effect after the existing scroll-tracking `useEffect`**

After the existing `useEffect` block (lines 87-105), add a new `useEffect` that fires once after the Hero animation settles. Insert this code after line 105:

```dart
// Peek scroll: when comments exist, briefly scroll up to reveal
// the "Thoughts" header after the card's Hero animation settles.
useEffect(() {
  if (currentPost.commentCount <= 0) return null;

  bool cancelled = false;

  Future<void> peek() async {
    // Wait for Hero animation + layout to settle
    await Future.delayed(const Duration(milliseconds: 400));
    if (cancelled ||
        !scrollController.hasClients ||
        scrollController.position.maxScrollExtent <= 0) {
      return;
    }
    // Peek distance: just enough to show the header (~30px scaled)
    final peekDistance = (30.0 * s).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
    scrollController.animateTo(
      peekDistance,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  peek();
  return () => cancelled = true;
}, [currentPost.commentCount]);
```

Key details:
- `cancelled` flag ensures we skip the animation if the widget unmounts or rebuilds before the delay fires
- `400ms` delay lets the Hero transition finish (~300ms) plus a small buffer
- `30.0 * s` peek distance is roughly the height of the "Thoughts" header text at scale — just enough to show it peeking from behind the squircle
- `Curves.easeOut` gives a gentle deceleration
- If the user has already scrolled (e.g., `maxScrollExtent <= 0`), we bail out
- Depends on `currentPost.commentCount` so it only fires once and re-evaluates if the post changes

- [ ] **Step 2: Hot-restart and verify**

1. Open a post **with** comments → after ~400ms, the "3 Thoughts" header should gently slide into view at the top edge of the visible content area
2. Open a post **without** comments → no peek animation, card stays at rest
3. Open a post with comments and immediately start scrolling → the peek should not fight the user's scroll (the `animateTo` will be overridden by user gesture)
4. Dismiss and reopen the same post → peek fires again

- [ ] **Step 3: Tune peek distance if needed**

If 30px scaled feels too subtle or too aggressive, adjust the constant. The goal is to show just the header text, not the comments themselves. Check on both smaller (iPhone SE) and larger (iPhone 16 Pro Max) screens.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/post_detail/views/post_detail_overlay.dart
git commit -m "feat: auto-peek Thoughts header when post has comments"
```

---

### Task 3: Edge-case hardening

**Files:**
- Modify: `lib/presentation/pages/post_detail/views/post_detail_overlay.dart` (same peek effect)

- [ ] **Step 1: Cancel peek if user scrolls before it fires**

Add a scroll listener that sets `cancelled = true` if the user scrolls before the 400ms delay. Update the peek effect from Task 2:

```dart
useEffect(() {
  if (currentPost.commentCount <= 0) return null;

  bool cancelled = false;

  void onUserScroll() {
    cancelled = true;
    scrollController.removeListener(onUserScroll);
  }

  scrollController.addListener(onUserScroll);

  Future<void> peek() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (cancelled ||
        !scrollController.hasClients ||
        scrollController.position.maxScrollExtent <= 0) {
      return;
    }
    final peekDistance = (30.0 * s).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
    scrollController.animateTo(
      peekDistance,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  peek();
  return () {
    cancelled = true;
    scrollController.removeListener(onUserScroll);
  };
}, [currentPost.commentCount]);
```

This ensures: if the user starts scrolling during the 400ms wait, the peek is skipped entirely rather than fighting their gesture.

- [ ] **Step 2: Test edge cases**

1. Open post with comments and immediately swipe up → peek should NOT fire
2. Open post with comments and wait → peek fires smoothly
3. Open post, let peek fire, then scroll freely → no jank or double-animation
4. Open post with `commentCount > 0` but comments still loading → header shows count from model, peek works (comments load async separately)

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/post_detail/views/post_detail_overlay.dart
git commit -m "fix: cancel thoughts peek when user scrolls before delay"
```
