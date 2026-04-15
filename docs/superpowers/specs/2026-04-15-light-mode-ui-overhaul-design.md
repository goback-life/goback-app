# Light Mode UI Overhaul — Design Spec

**Date:** 2026-04-15
**Scope:** Every page and component in the app EXCEPT: nav overlay, manual lockout page, lockout complete page, friends locked out page.

---

## 0. Current Inconsistencies (Must Fix)

The audit revealed the app has no single color approach — fixing this is the real work, not just swapping dark↔light.

| # | Issue | Fix Strategy |
|---|-------|-------------|
| 1 | Mixed backgrounds: some pages use `colorScheme.surface`, others use `MainColors.dark` directly | Unify: all non-excluded pages use `colorScheme.surface`. Remove explicit `MainColors.dark` from feed, profile, circle_profile, tutorial pages. |
| 2 | Hardcoded surface variants (`0xFF2A2A2A`, `0xFF222222`) in stats cards, profile, sheets | Replace with `colorScheme.surfaceContainer` / `surfaceContainerHigh` tokens |
| 3 | Hardcoded overlay/shadow colors (`0x40191919`, `0x40000000`) | Replace with `colorScheme.shadow.withValues(alpha: X)` |
| 4 | Activity bubble cloud: 8 hardcoded hex colors | Move to MainColors constants (these are decorative, keep as-is but define centrally) |
| 5 | Grey usage only in tutorial/onboarding, rest of app uses colorScheme | Replace all `MainColors.grey*` in tutorial with `colorScheme.onSurface` + alpha or `colorScheme.outline` |
| 6 | Text colors: share cards + tutorial use `MainColors.white`, rest uses `colorScheme.onSurface` | Unify to `colorScheme.onSurface` everywhere except excluded pages and share cards (share cards render on dark for export, keep white) |
| 7 | `withOpacity()` and `withValues(alpha:)` used interchangeably | Standardize on `withValues(alpha:)` (the newer API) |
| 8 | No standard divider color — menus use `colorScheme.shadow`, others use `colorScheme.outline` with varying alphas | Standardize: dividers use `colorScheme.outline.withValues(alpha: 0.15)` |
| 9 | Success/failure colors hardcoded in share card | Move to MainColors if reused; leave if truly one-off |

---

## 1. Theme Layer — The Foundation

All changes flow from updating `main_theme.dart` and `main_colors.dart`. Pages already using `colorScheme.*` tokens will automatically pick up the new colors.

### main_colors.dart

```
// New
static const Color surface = Color(0xFFF8F7F5);  // soft warm white — page bg

// Updated
static const Color accent = Color(0xFF5A8FB2);    // slightly warmer blue

// Unchanged
static const Color dark = Color(0xFF1A1A1A);      // text on light bg + excluded page bg
static const Color white = Color(0xFFFFFFFF);      // text on dark surfaces (excluded pages)
```

### main_theme.dart — ColorScheme

Switch from `ColorScheme.dark(...)` to `ColorScheme.light(...)`:

| Token | Current (dark) | New (light) |
|-------|---------------|-------------|
| `brightness` | `dark` | `light` |
| `surface` | `#1A1A1A` | `#F8F7F5` |
| `onSurface` | `#FFFFFF` | `#1A1A1A` |
| `primary` | accent | accent |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `surfaceContainerLowest` | `#0F0F0F` | `#FFFFFF` |
| `surfaceContainerLow` | `#1A1A1A` | `#F5F4F2` |
| `surfaceContainer` | `#222222` | `#EFEEEC` |
| `surfaceContainerHigh` | `#2A2A2A` | `#E8E7E5` |
| `surfaceContainerHighest` | `#333333` | `#E0DFDD` |
| `outline` | `#333333` | `#C8C7C5` |
| `outlineVariant` | `#444444` | `#B0AFAD` |
| `onSurfaceVariant` | `#CCCCCC` | `#5A5A58` |
| `shadow` | dark default | `#1A1A1A` (low alpha in usage) |
| `surfaceDim` | `#121212` | `#E0DFDD` |
| `error` | red500 | red500 |

### scaffoldBackgroundColor

Set to `colorScheme.surface` (already the case in main_theme.dart line 66). This means pages using `Theme.of(context).colorScheme.surface` or the default scaffold bg get the new color automatically.

---

## 2. Button Shape

- CTA theme `borderRadius`: `Radius.circular(900)` → `Radius.circular(10)`
- `call_to_action_style.dart` default: `12` → `10`
- Search bars: `BorderRadius.circular(99)` → `BorderRadius.circular(10)`
- Date badge, banners, chips: audit each and set to `10` where pill-shaped
- Bottom sheets `borderRadius.vertical(top: 24)`: keep at 24 (these aren't buttons)
- **Exception:** Circular avatars, notification dots, and shape indicators stay round

---

## 3. Accent Color

- `#598EB5` → `#5A8FB2` — very subtle warm nudge
- Single change in `MainColors.accent`, propagates everywhere

---

## 4. Glass on Light Backgrounds

### Fallback renderer (`_ShaderGlass` / `_RoundedGlassOverlay`)

The current glass effects use white highlights designed for dark backgrounds. On light, these become invisible. Adjustments:

- Tint fill alpha: `0.3` → `0.4` (stronger tint presence)
- Light tint layer (`Colors.white @ 0.08`): remove entirely — white-on-white is invisible
- Body gradient: flip from `white→transparent→black` to `accent.withValues(alpha: 0.03)→transparent`
- Edge highlight: change from white gradient to accent-tinted gradient at low alpha
- Box shadow color: `Color(0x40191919)` → `colorScheme.shadow.withValues(alpha: 0.12)` (softer on light)
- Inner highlight: reduce or flip to subtle accent glow

### Native glass (iOS 26+)

- Feed lockout triangle opacity: `0.3` → `0.5`
- Native glass generally handles light backgrounds well (SwiftUI `.glassEffect()` adapts), but tint colors should be strengthened

### Per-component glass adjustments

- `GlassVariant.clear` with no tint (date overlay, new posts banner): add `tint: MainColors.accent` so they're visible
- Search bar glass (no tint): add subtle accent tint
- All glass should read as a subtle frosted blue-tinted surface

---

## 5. Page-by-Page Migration Strategy

### Tier 1 — Automatic (already using colorScheme tokens)

These pages will mostly work after the theme layer change. Need minor review:

- home, notifications, settings, invite_to_circle, review_circle, join_circle, sign_in, otp, edit_profile, publish_content, content_editor, objective, visibility_selection, your_circle

### Tier 2 — Explicit MainColors.dark override (must fix)

These pages hardcode `MainColors.dark` as background, bypassing the theme:

- `feed/feed_page.dart` → replace `MainColors.dark` with `colorScheme.surface`
- `profile/profile_page.dart` → replace `MainColors.dark` with `colorScheme.surface`
- `profile/views/limited_profile_view.dart` → replace `MainColors.dark`
- `circle_profile/circle_profile_page.dart` → replace `MainColors.dark`
- `tutorial/tutorial_page.dart` → replace `MainColors.dark`

### Tier 3 — Hardcoded colors (must replace with tokens)

- `stats_share_card.dart:145` — `0xFF2A2A2A` → `colorScheme.surfaceContainerHigh`
- `stats_card.dart:23` — `0xFF2A2A2A` → `colorScheme.surfaceContainerHigh`
- `profile_page.dart:100` — `0xFF2A2A2A` → `colorScheme.surfaceContainerHigh`
- `lockout_bottom_sheet.dart:86` — `0xFF222222` → `colorScheme.surfaceContainer`
- `post_detail_overlay_reactions.dart:278,357` — `0xFF1A1A1A` → `colorScheme.surface`

### Tier 4 — Text color fixes

Everywhere `MainColors.white` is used for text on what will now be a light background:
- Feed components (post card username, date overlay, banner text)
- Tutorial components (tooltip text, search field, tab text)
- Onboarding overlay text
- Mention overlay text

Replace with `colorScheme.onSurface` or `MainColors.dark`.

**Keep `MainColors.white`** in:
- Share cards (rendered on dark for export/sharing)
- Excluded pages
- Text on accent-colored filled buttons (white-on-blue stays correct)

### Tier 5 — Grey cleanup

Replace all `MainColors.grey*` usage in non-excluded pages:
- `grey100` (hint text) → `colorScheme.onSurface.withValues(alpha: 0.4)`
- `grey300` (borders) → `colorScheme.outline`
- `grey500` (secondary text) → `colorScheme.onSurfaceVariant`

---

## 6. Excluded Pages (NO changes)

- `lib/presentation/pages/friends_locked_out/` — nav page
- `lib/presentation/pages/manual_lockout/` — lockout timer
- `lib/presentation/pages/lockout_complete/` — celebration
- `lib/presentation/components/nav_overlay/` — hold-to-navigate overlay

These keep their current dark theme, colors, and glass settings entirely unchanged.

---

## 7. Consistency Checklist

- [ ] Theme layer updated (main_theme.dart, main_colors.dart)
- [ ] All non-excluded pages use `colorScheme.surface` background (no explicit MainColors.dark)
- [ ] All hardcoded color literals replaced with colorScheme tokens
- [ ] All text uses `colorScheme.onSurface` (not MainColors.white) on light backgrounds
- [ ] All `MainColors.grey*` replaced with colorScheme equivalents
- [ ] All CTAs/buttons use borderRadius 10
- [ ] All search bars use borderRadius 10
- [ ] All pill-shaped chips/badges use borderRadius 10
- [ ] Glass elements visible on light background (tinted, opacity bumped)
- [ ] Glass fallback renderer updated for light mode
- [ ] Accent color updated to warmer tone
- [ ] Dividers standardized to `colorScheme.outline.withValues(alpha: 0.15)`
- [ ] `withOpacity()` → `withValues(alpha:)` standardized
- [ ] Excluded pages verified unchanged
- [ ] Share cards verified still correct (white text on dark)
- [ ] App builds and runs without errors
