# Light Mode UI Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the entire app from dark mode to a polished, consistent light mode with squared buttons, warmer accent, and visible glass elements.

**Architecture:** Theme-first approach — update `main_theme.dart` ColorScheme from dark→light so all pages using `colorScheme.*` tokens flip automatically. Then fix pages that bypass the theme with hardcoded colors. Finally, sweep every page with dedicated agents to catch inconsistencies.

**Tech Stack:** Flutter 3.35.5 (FVM), Dart, Material Design 3 ColorScheme

**Excluded from ALL changes:**
- `lib/presentation/pages/friends_locked_out/` (nav page)
- `lib/presentation/pages/manual_lockout/` (lockout timer)
- `lib/presentation/pages/lockout_complete/` (celebration)
- `lib/presentation/components/nav_overlay/` (hold-to-navigate)

---

### Task 1: Update MainColors — add surface, warm accent

**Files:**
- Modify: `lib/presentation/themes/constants/main_colors.dart`

- [ ] **Step 1: Add surface color and update accent**

```dart
// In MainColors class, add after the dark constant:
static const Color surface = Color(0xFFF8F7F5);

// Update accent:
static const Color accent = Color(0xFF5A8FB2);  // was 0xFF598EB5
```

- [ ] **Step 2: Verify no build errors**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/themes/constants/main_colors.dart
git commit -m "feat: add MainColors.surface, warm accent color"
```

---

### Task 2: Flip ColorScheme from dark to light

**Files:**
- Modify: `lib/presentation/themes/main_theme.dart`

This is the highest-leverage change. Every page using `colorScheme.surface`, `colorScheme.onSurface`, etc. will automatically flip.

- [ ] **Step 1: Update the ColorScheme in MainTheme.colorScheme getter**

Replace the entire `ColorScheme(...)` constructor:

```dart
return const ColorScheme(
  brightness: Brightness.light,
  // primaries
  primary: MainColors.accent,
  onPrimary: MainColors.white,
  primaryContainer: MainColors.accent,
  onPrimaryContainer: MainColors.white,
  // secondaries
  secondary: MainColors.dark,
  onSecondary: MainColors.white,
  secondaryContainer: MainColors.surface,
  onSecondaryContainer: MainColors.dark,
  // tertiary
  tertiary: MainColors.accent,
  onTertiary: MainColors.white,
  tertiaryContainer: MainColors.accent,
  onTertiaryContainer: MainColors.white,
  // error
  error: MainColors.red500,
  onError: MainColors.white,
  errorContainer: MainColors.red100,
  onErrorContainer: MainColors.red500,
  // surface
  surface: MainColors.surface,
  surfaceDim: Color(0xFFE0DFDD),
  onSurface: MainColors.dark,
  onSurfaceVariant: Color(0xFF5A5A58),
  // outline
  outline: Color(0xFFC8C7C5),
  outlineVariant: Color(0xFFB0AFAD),
  // shadows and scrims
  shadow: MainColors.dark,
  scrim: MainColors.dark,
  // containers — light-mode elevated surfaces
  surfaceContainerLowest: MainColors.white,
  surfaceContainerLow: Color(0xFFF5F4F2),
  surfaceContainer: Color(0xFFEFEEEC),
  surfaceContainerHigh: Color(0xFFE8E7E5),
  surfaceContainerHighest: Color(0xFFE0DFDD),
  // banner variants
  tertiaryFixedDim: MainColors.surface,
  onTertiaryFixedVariant: MainColors.dark,
  // inverse (for CTAs that need dark-on-light contrast)
  inverseSurface: MainColors.dark,
  onInverseSurface: MainColors.white,
  inversePrimary: MainColors.accent,
);
```

- [ ] **Step 2: Update the CTA borderRadius in themeData extensions**

In the `themeData` getter, change the `CallToActionStyle` extension:

```dart
// Change borderRadius from Radius.circular(900) to Radius.circular(10):
CallToActionStyle(
  mode: CallToAction.filled,
  theme: CallToActionTheme.primary,
  horizontalMargin: 20,
  borderRadius: const BorderRadius.all(Radius.circular(10)),
  height: 50,
  iconOnTheRight: false,
),
```

- [ ] **Step 3: Verify build compiles**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/themes/main_theme.dart
git commit -m "feat: flip ColorScheme to light mode, button radius to 10"
```

---

### Task 3: Update CTA style defaults

**Files:**
- Modify: `lib/presentation/components/buttons/call_to_action/theming/call_to_action_style.dart` (this is a `part of` file inside `call_to_action.dart`)

- [ ] **Step 1: Update the defaultStyle borderRadius**

```dart
// In CallToActionStyle.defaultStyle, change:
borderRadius: BorderRadius.all(Radius.circular(12)),
// To:
borderRadius: BorderRadius.all(Radius.circular(10)),

// Also update the constructor default:
this.borderRadius = const BorderRadius.all(Radius.circular(10)),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/components/buttons/call_to_action/theming/call_to_action_style.dart
git commit -m "feat: CTA default borderRadius 12 -> 10"
```

---

### Task 4: Update search bar border radius

**Files:**
- Modify: `lib/presentation/components/search_input_decoration.dart`

- [ ] **Step 1: Change all BorderRadius.circular(99) to BorderRadius.circular(10)**

There are 3 instances in this file (border, enabledBorder, focusedBorder). Change all from `99` to `10`.

```dart
border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide.none,
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/components/search_input_decoration.dart
git commit -m "feat: search bar borderRadius 99 -> 10"
```

---

### Task 5: Update glass fallback renderer for light backgrounds

**Files:**
- Modify: `lib/presentation/components/glass/app_glass_container.dart`

The current glass overlay uses white highlights that are invisible on white backgrounds. Flip to use accent-tinted shading.

- [ ] **Step 1: Update `_RoundedGlassOverlay.paint()` method**

Replace the entire paint method body in `_RoundedGlassOverlay`:

```dart
@override
void paint(Canvas canvas, Size size) {
  final rrect = RRect.fromRectAndRadius(
    Offset.zero & size,
    Radius.circular(cornerRadius),
  );
  final bounds = Offset.zero & size;

  // 0. Tint fill — colored glass when a tint is specified
  if (tint != null) {
    canvas.drawRRect(rrect, Paint()..color = tint!.withValues(alpha: 0.4));
  }

  // 1. Subtle surface tint — gives glass presence on light backgrounds
  canvas.drawRRect(
    rrect,
    Paint()..color = const Color(0xFF5A8FB2).withValues(alpha: 0.04),
  );

  // -- Clipped interior --
  canvas.save();
  canvas.clipRRect(rrect);

  // 2. Body gradient: subtle darkening NW -> SE
  canvas.drawPaint(
    Paint()
      ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
        Colors.black.withValues(alpha: 0.02),
        Colors.black.withValues(alpha: 0.05),
      ]),
  );

  // 3. Inner shadow — soft darkening on lower-right edges
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.06),
      ]),
  );

  canvas.restore();

  // 4. Edge highlight — subtle border definition
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        [
          Colors.white.withValues(alpha: 0.6),
          Colors.black.withValues(alpha: 0.08),
          Colors.black.withValues(alpha: 0.04),
        ],
        [0.0, 0.45, 0.75],
      ),
  );
}
```

- [ ] **Step 2: Update the box shadow in `_ShaderGlass` to be softer**

In `_ShaderGlass.build()`, change the boxShadow:

```dart
boxShadow: const [
  BoxShadow(
    color: Color(0x18191919),
    blurRadius: 6,
    offset: Offset(0, 2),
  ),
],
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/components/glass/app_glass_container.dart
git commit -m "feat: update glass fallback renderer for light backgrounds"
```

---

### Task 6: Fix Tier-2 pages — explicit MainColors.dark backgrounds

These pages hardcode `MainColors.dark` as background instead of using `colorScheme.surface`. Fix each one.

**Files:**
- Modify: `lib/presentation/pages/feed/feed_page.dart`
- Modify: `lib/presentation/pages/profile/profile_page.dart`
- Modify: `lib/presentation/pages/profile/views/limited_profile_view.dart`
- Modify: `lib/presentation/pages/circle_profile/circle_profile_page.dart`
- Modify: `lib/presentation/pages/tutorial/tutorial_page.dart`
- Modify: `lib/presentation/pages/your_circle/your_circle_page.dart`

- [ ] **Step 1: feed_page.dart**

Change `backgroundColor: MainColors.dark` to use the theme. The file imports MainColors, so add a `Theme.of(context)` lookup:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return AppGlassLayer(
    child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const FeedView(),
    ),
  );
}
```

Remove the `MainColors` import if no longer used.

- [ ] **Step 2: profile_page.dart**

Change `backgroundColor: MainColors.dark` to `backgroundColor: Theme.of(context).colorScheme.surface`.

Also fix the `_ProfileDropdownMenu`:
- `color: const Color(0xFF2A2A2A)` → `color: Theme.of(context).colorScheme.surfaceContainerHigh`
- `color: Color(0x40000000)` shadow → `color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08)`
- `color: MainColors.white` text → `color: Theme.of(context).colorScheme.onSurface`

- [ ] **Step 3: limited_profile_view.dart**

- `backgroundColor: MainColors.dark` → `backgroundColor: Theme.of(context).colorScheme.surface`
- `color: MainColors.white` on back icon → `color: Theme.of(context).colorScheme.onSurface`
- `color: MainColors.white` on username text → `color: Theme.of(context).colorScheme.onSurface`
- `backgroundColor: MainColors.grey500` (disabled button) → `backgroundColor: Theme.of(context).colorScheme.outline`
- `foregroundColor: MainColors.white` → `foregroundColor: MainColors.white` (keep — white on accent/blue button is correct)
- `color: MainColors.white` on spinner → `color: MainColors.white` (keep — on accent button)

- [ ] **Step 4: circle_profile_page.dart**

- `backgroundColor: MainColors.dark` → `backgroundColor: Theme.of(context).colorScheme.surface`
- `color: MainColors.white` on back icon → `color: Theme.of(context).colorScheme.onSurface`

- [ ] **Step 5: tutorial_page.dart**

- `backgroundColor: MainColors.dark` → `backgroundColor: Theme.of(context).colorScheme.surface`

- [ ] **Step 6: your_circle_page.dart**

- `backgroundColor: MainColors.dark` → `backgroundColor: Theme.of(context).colorScheme.surface`
- In `_TabPill`: `color: MainColors.white` → `color: Theme.of(context).colorScheme.onSurface`
- In `_TabPill`: `MainColors.white.withOpacity(0.5)` → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)`
- In `_TabPill`: `MainColors.accent.withOpacity(0.25)` → `MainColors.accent.withValues(alpha: 0.25)`
- Change `.withOpacity(` to `.withValues(alpha:` throughout

- [ ] **Step 7: Verify build**

Run: `fvm flutter analyze --no-fatal-warnings`

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/pages/feed/feed_page.dart \
        lib/presentation/pages/profile/profile_page.dart \
        lib/presentation/pages/profile/views/limited_profile_view.dart \
        lib/presentation/pages/circle_profile/circle_profile_page.dart \
        lib/presentation/pages/tutorial/tutorial_page.dart \
        lib/presentation/pages/your_circle/your_circle_page.dart
git commit -m "feat: migrate hardcoded dark backgrounds to colorScheme.surface"
```

---

### Task 7: Fix feed components — text/icon colors for light mode

**Files:**
- Modify: `lib/presentation/pages/feed/components/feed_post_card.dart`
- Modify: `lib/presentation/pages/feed/components/feed_date_overlay.dart`
- Modify: `lib/presentation/pages/feed/components/feed_new_posts_banner.dart`
- Modify: `lib/presentation/pages/feed/components/feed_posts_list.dart`
- Modify: `lib/presentation/pages/feed/views/feed_view.dart`
- Modify: `lib/presentation/pages/feed/components/feed_lockout_button.dart`

- [ ] **Step 1: feed_post_card.dart**

- Username text `color: MainColors.white` → `color: Theme.of(context).colorScheme.onSurface`
- Placeholder containers `color: MainColors.dark` → `color: Theme.of(context).colorScheme.surfaceContainerHigh` (so placeholder isn't jarring black on white)

- [ ] **Step 2: feed_date_overlay.dart**

- Text `color: MainColors.white` → `color: MainColors.dark` (text sits on glass, which will be light-tinted — dark text for contrast)

- [ ] **Step 3: feed_new_posts_banner.dart**

- Icon `colorFilter: MainColors.white.asSrcIn` → `colorFilter: MainColors.dark.asSrcIn`
- Text `color: MainColors.white` → `color: MainColors.dark`

- [ ] **Step 4: feed_posts_list.dart**

- Delete icon `color: MainColors.white` → `color: Theme.of(context).colorScheme.onSurface`

- [ ] **Step 5: feed_view.dart**

- Loading spinner `color: MainColors.white` → `color: MainColors.dark`

- [ ] **Step 6: feed_lockout_button.dart**

- Native glass opacity `0.3` → `0.5` (more visible on light bg)
- Fallback accent tint alpha `0.20` → `0.40`
- Shadow color `Color(0xFF191919).withValues(alpha: 0.25)` → `Color(0xFF191919).withValues(alpha: 0.12)`
- Glass overlay white highlights: reduce alphas to work on light background
  - Reflection alpha: `0.80` → `0.40`
  - Reflection mid: base from `0.20` → `0.10`
  - Caustic alpha: base from `0.28` → `0.15`

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/pages/feed/components/ lib/presentation/pages/feed/views/
git commit -m "feat: update feed components for light mode"
```

---

### Task 8: Fix hardcoded colors in post_detail, home, and profile components

**Files:**
- Modify: `lib/presentation/pages/post_detail/components/post_detail_overlay_reactions.dart` (lines 278, 357: `Color(0xFF1A1A1A)`)
- Modify: `lib/presentation/pages/profile/components/stats_section/stats_card.dart` (line 23: `Color(0xFF2A2A2A)`)
- Modify: `lib/presentation/components/share_card/stats_share_card.dart` (line 145: `Color(0xFF2A2A2A)`)
- Modify: `lib/presentation/pages/home/components/lockout_bottom_sheet.dart` (line 86: `Color(0xFF222222)`)

- [ ] **Step 1: Replace each hardcoded color with the appropriate colorScheme token**

For each file, read it first, then replace:
- `Color(0xFF1A1A1A)` → `Theme.of(context).colorScheme.surface`
- `Color(0xFF2A2A2A)` → `Theme.of(context).colorScheme.surfaceContainerHigh`
- `Color(0xFF222222)` → `Theme.of(context).colorScheme.surfaceContainer`

**Exception:** `stats_share_card.dart` renders for image export on dark background — keep its hardcoded colors. Only fix `stats_card.dart` and `post_detail_overlay_reactions.dart`.

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: replace hardcoded color literals with colorScheme tokens"
```

---

### Task 9: Agent sweep — Tutorial & Onboarding pages

**Agent instruction:** Read EVERY file in these directories and fix ALL color inconsistencies:
- `lib/presentation/pages/tutorial/` (all files)
- `lib/presentation/pages/create_profile/` (all files)
- `lib/presentation/pages/sign_in/` (all files)
- `lib/presentation/pages/otp/` (all files)
- `lib/presentation/components/onboarding/` (all files)

**What to fix:**
- [ ] All `MainColors.grey*` references → replace with `colorScheme.onSurfaceVariant` (for text), `colorScheme.outline` (for borders), or `colorScheme.onSurface.withValues(alpha: X)` (for hints)
- [ ] All `MainColors.white` used as text color on light backgrounds → `colorScheme.onSurface` or `MainColors.dark`
- [ ] All `MainColors.dark` used as background → `colorScheme.surface` (via `Theme.of(context)`)
- [ ] All `withOpacity()` → `withValues(alpha:)`
- [ ] All pill-shaped elements (borderRadius >= 20 on buttons/chips) → borderRadius 10
- [ ] Verify glass components have accent tint
- [ ] **Do NOT change** any files in excluded directories

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — tutorial & onboarding"
```

---

### Task 10: Agent sweep — Feed & Home pages

**Agent instruction:** Read EVERY file in these directories and fix ALL remaining color inconsistencies:
- `lib/presentation/pages/feed/` (all files)
- `lib/presentation/pages/home/` (all files)

**What to fix:**
- [ ] All `MainColors.white` text on light backgrounds → `colorScheme.onSurface` or `MainColors.dark`
- [ ] All hardcoded `Color(0x...)` → colorScheme tokens
- [ ] All `withOpacity()` → `withValues(alpha:)`
- [ ] Glass tints — ensure all glass elements have accent tint for visibility
- [ ] Pill-shaped elements → borderRadius 10
- [ ] Verify `home_date_badge.dart` glass shows on light bg (it uses accent tint — should be OK)
- [ ] Verify `home_feed_post_card.dart` text colors (it uses `MainColors.dark` already — should be OK on light bg)
- [ ] Check `memorable_post_selection_dialog.dart`, `dnd_prompt_dialog.dart` backgrounds
- [ ] Check `lockout_bottom_sheet.dart` background color
- [ ] **Do NOT change** any files in excluded directories

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — feed & home"
```

---

### Task 11: Agent sweep — Profile & Circle pages

**Agent instruction:** Read EVERY file in these directories and fix ALL color inconsistencies:
- `lib/presentation/pages/profile/` (all files)
- `lib/presentation/pages/circle_profile/` (all files)
- `lib/presentation/pages/external_profile/` (all files)
- `lib/presentation/pages/profile_shared/` (all files)

**What to fix:**
- [ ] All `MainColors.white` text on light backgrounds → `colorScheme.onSurface`
- [ ] All hardcoded `Color(0x...)` → colorScheme tokens
- [ ] `profile_hamburger_menu.dart` — overlay color `Color(0x40191919)` → `colorScheme.shadow.withValues(alpha: 0.08)`
- [ ] `stats_card.dart` — `Color(0xFF2A2A2A)` background → `colorScheme.surfaceContainerHigh`
- [ ] Calendar section components — verify text colors contrast on light
- [ ] `profile_tab_toggle.dart` — verify tab colors work on light
- [ ] `activity_bubble_cloud_painter.dart` — decorative colors can stay, but verify they look OK on light (may need slight saturation bump)
- [ ] `lockout_bar_chart_painter.dart` — verify chart colors work on light
- [ ] Menu dividers — standardize to `colorScheme.outline.withValues(alpha: 0.15)`
- [ ] All `withOpacity()` → `withValues(alpha:)`
- [ ] **Do NOT change** `stats_share_card.dart` or `lockout_share_card.dart` (these render on dark for export)

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — profile & circle pages"
```

---

### Task 12: Agent sweep — Post Detail page

**Agent instruction:** Read EVERY file in `lib/presentation/pages/post_detail/` and fix ALL color inconsistencies.

**What to fix:**
- [ ] All `MainColors.white` text on light backgrounds → `colorScheme.onSurface`
- [ ] All hardcoded `Color(0x...)` backgrounds → colorScheme tokens
- [ ] `post_detail_overlay.dart` — overlay background, glass shadow color `Color(0x40191919)`
- [ ] `post_detail_overlay_reactions.dart` — modal backgrounds `Color(0xFF1A1A1A)` → `colorScheme.surface`
- [ ] `post_detail_overlay_content.dart` — placeholder `Color(0xFF555555)` → `colorScheme.outline`
- [ ] `post_detail_overlay_input.dart` — text field colors, borders
- [ ] `post_detail_comment_input.dart` — border `colorScheme.outline.withValues(alpha: 0.1)` → keep (already correct)
- [ ] Comment/reaction list modals — backgrounds, text colors
- [ ] Actions menu — divider consistency
- [ ] All `withOpacity()` → `withValues(alpha:)`
- [ ] All pill-shaped elements → borderRadius 10

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — post detail"
```

---

### Task 13: Agent sweep — Your Circle, Notifications, Settings

**Agent instruction:** Read EVERY file in these directories and fix ALL color inconsistencies:
- `lib/presentation/pages/your_circle/` (all files)
- `lib/presentation/pages/notifications/` (all files)
- `lib/presentation/pages/settings/` (all files)
- `lib/presentation/pages/invite_to_circle/` (all files)
- `lib/presentation/pages/join_circle/` (all files)
- `lib/presentation/pages/review_circle/` (all files)

**What to fix:**
- [ ] `your_circle_page.dart` — already fixed in Task 6 but check child views and components
- [ ] `invite_card_popup.dart`, `invite_card_contacts.dart` — `Color(0x99FFFFFF)`, `Color(0x66FFFFFF)` overlays → `colorScheme.surface.withValues(alpha: 0.6/0.4)`
- [ ] `receive_code_card_popup.dart` — check colors
- [ ] `leaderboard_tile.dart` — gold medal `Color(0xFFFFD700)` can stay (decorative), but check text colors
- [ ] `connection_request_tiles.dart` — dynamic border colors, text colors
- [ ] `your_circle_search_pill.dart` — pill shape → borderRadius 10
- [ ] `your_circle_friend_tile.dart` — text colors
- [ ] Notification items — verify text contrast on light
- [ ] Settings menu items — verify glass shows, text readable
- [ ] `notifications_switch.dart` — glass tint check
- [ ] All `MainColors.white` text on light backgrounds → `colorScheme.onSurface`
- [ ] All `withOpacity()` → `withValues(alpha:)`

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — circle, notifications, settings"
```

---

### Task 14: Agent sweep — Content Editor, Publish, Visibility, Objective

**Agent instruction:** Read EVERY file in these directories and fix ALL color inconsistencies:
- `lib/presentation/pages/content_editor/` (all files)
- `lib/presentation/pages/publish_content/` (all files)
- `lib/presentation/pages/visibility_selection/` (all files)
- `lib/presentation/pages/objective/` (all files)
- `lib/presentation/pages/edit_profile/` (all files)

**What to fix:**
- [ ] `lockout_post_editor_view.dart` — `Color(0x33D9D9D9)` overlay → `colorScheme.outline.withValues(alpha: 0.15)`
- [ ] `content_editor_view.dart` — background uses `colorScheme.surface` (should be OK), check child colors
- [ ] `content_editor_text_post.dart`, `content_editor_selected_media.dart`, `content_editor_user_chip.dart` — text/icon colors
- [ ] All `MainColors.white` text → `colorScheme.onSurface` where on light bg
- [ ] All `withOpacity()` → `withValues(alpha:)`

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — editor, publish, visibility, objective"
```

---

### Task 15: Agent sweep — Shared components (alerts, sheets, form fields, search)

**Agent instruction:** Read EVERY file in these directories and fix ALL color inconsistencies:
- `lib/presentation/components/alerts/` (all files)
- `lib/presentation/components/sheets/` (all files)
- `lib/presentation/components/form_field/` (all files)
- `lib/presentation/components/main_search_bar.dart`
- `lib/presentation/components/main_empty_state.dart`
- `lib/presentation/components/mention_text_field/` (all files)
- `lib/presentation/components/text/` (all files)
- `lib/presentation/components/profile_image/` (all files)
- `lib/presentation/components/main_data_loader.dart`
- `lib/presentation/components/video_player/` (all files)
- `lib/presentation/components/frame_picker/` (all files)
- `lib/presentation/components/parent_post_preview/` (all files)
- `lib/presentation/components/goback_logo.dart`

**What to fix:**
- [ ] `main_alert.dart` — dialog background, text colors, button colors
- [ ] `main_snackbar.dart` — glass tint (uses accent — should be OK), text color
- [ ] Sheet backgrounds — `content_type_picker_sheet.dart`, `image_picker_sheet.dart`, `media_source_picker_sheet.dart`, `media_type_picker_sheet.dart`
- [ ] Form field glass containers — ensure accent tint present
- [ ] `input_decoration.dart` — `onSurfaceVariant` hint text (should be OK)
- [ ] `main_search_bar.dart` — glass config, ensure tint present for visibility
- [ ] `mention_overlay.dart` — `MainColors.white` text → `colorScheme.onSurface`
- [ ] `phone_number_form_field.dart` — glass tint check
- [ ] `goback_logo.dart` — color check
- [ ] All `withOpacity()` → `withValues(alpha:)`

- [ ] **Commit when done**

```bash
git commit -m "feat: light mode consistency — shared components"
```

---

### Task 16: Agent sweep — Glass tint audit (all glass usages)

**Agent instruction:** Search the ENTIRE codebase for every `GlassConfig(` and `AppGlassContainer(` usage. For each one:

- [ ] Verify it has a `tint` parameter. If `tint` is null/missing and the component is on a light background, add `tint: MainColors.accent`
- [ ] Verify glass components are NOT in excluded directories (skip those)
- [ ] For `GlassVariant.clear` components: they have the least visual presence — ensure they have a tint
- [ ] For components with `opacity` < 1.0: consider bumping slightly (e.g., 0.3 → 0.5)
- [ ] List every glass usage found and what action was taken (tint added, opacity bumped, or no change needed)

- [ ] **Commit when done**

```bash
git commit -m "feat: ensure all glass elements visible on light backgrounds"
```

---

### Task 17: Agent sweep — Pill shape audit (all borderRadius >= 20)

**Agent instruction:** Search the ENTIRE codebase (excluding the 4 excluded directories) for:
- `BorderRadius.circular(` with values >= 20
- `Radius.circular(` with values >= 20
- `StadiumBorder`
- `borderRadius:` with values >= 20

For each hit, decide:
- [ ] If it's a **button, chip, badge, search bar, or tab pill** → change to 10
- [ ] If it's a **bottom sheet top radius** (24) → keep at 24 (these aren't buttons)
- [ ] If it's a **circular avatar** or **notification dot** → keep round
- [ ] If it's a **glass container cornerRadius** used decoratively → evaluate case by case (reduce to 10-14 for consistency)
- [ ] If it's a **tooltip or popup** → reduce to match (10-14)

List every hit and what action was taken.

- [ ] **Commit when done**

```bash
git commit -m "feat: standardize border radius across app"
```

---

### Task 18: Agent sweep — withOpacity → withValues(alpha:) migration

**Agent instruction:** Search the ENTIRE codebase (excluding the 4 excluded directories) for `.withOpacity(` and replace every instance with `.withValues(alpha:`.

- [ ] Find all `.withOpacity(` calls
- [ ] Replace each with `.withValues(alpha:` — the value stays the same
- [ ] Example: `MainColors.accent.withOpacity(0.25)` → `MainColors.accent.withValues(alpha: 0.25)`

- [ ] **Commit when done**

```bash
git commit -m "refactor: migrate withOpacity to withValues(alpha:)"
```

---

### Task 19: Final verification — build, analyze, visual check

- [ ] **Step 1: Run build_runner (in case any model files were touched)**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Run analyzer**

Run: `fvm flutter analyze --no-fatal-warnings`
Fix any errors.

- [ ] **Step 3: Run tests**

Run: `fvm flutter test`
Fix any failures.

- [ ] **Step 4: Verify excluded pages are unchanged**

Run: `git diff HEAD~20 -- lib/presentation/pages/friends_locked_out/ lib/presentation/pages/manual_lockout/ lib/presentation/pages/lockout_complete/ lib/presentation/components/nav_overlay/`

Expected: no output (no changes to excluded files).

- [ ] **Step 5: Final commit if any fixes were needed**

```bash
git commit -m "fix: resolve build errors from light mode migration"
```

---

## Execution Notes

**Tasks 1-8** are sequential — each builds on the previous.

**Tasks 9-18** are the agent sweeps — these can run in **parallel batches**:
- Batch A (pages): Tasks 9, 10, 11, 12, 13, 14 — each agent sweeps a different set of pages
- Batch B (cross-cutting): Tasks 15, 16, 17, 18 — each agent sweeps the whole codebase for one concern

Run Batch A first (page-level fixes), then Batch B (global audits), then Task 19 (verification).

**Each agent should:**
1. Read every file in its assigned directories
2. List all issues found with file:line references
3. Fix each issue
4. Run `fvm flutter analyze --no-fatal-warnings` before committing
5. Commit with the specified message
