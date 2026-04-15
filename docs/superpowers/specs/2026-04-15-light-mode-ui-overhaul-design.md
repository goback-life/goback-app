# Light Mode UI Overhaul — Design Spec

**Date:** 2026-04-15
**Scope:** Every page and component in the app EXCEPT: nav overlay, manual lockout page, lockout complete page.

---

## 1. Button Shape

**Change:** All pill-shaped buttons → squared with rounded edges.

- CTA theme default `borderRadius`: `Radius.circular(900)` → `Radius.circular(10)`
- Also update `call_to_action_style.dart` default (currently `borderRadius: 12`) → `10`
- Search bars with `BorderRadius.circular(99)` → `BorderRadius.circular(10)`
- Any other pill-shaped UI elements (banners, chips, badges) → consistent `10` radius
- **Exception:** Circular avatars and fully round indicators (e.g., notification dots) stay round — they aren't "pill-shaped buttons"

---

## 2. Light Mode Background

**Change:** Dark backgrounds → soft warm white.

- New background color: `~#F8F7F5` (soft warm white) — add as `MainColors.surface` or replace usage of `MainColors.dark` in non-excluded pages
- `MainColors.dark` (`#1A1A1A`) remains defined (used by excluded pages) but is no longer the default background
- Scaffold `backgroundColor` on all non-excluded pages: `MainColors.dark` → new surface color
- Material theme `brightness`: `dark` → `light`

### Text & Icon Color Flips

Everywhere background flips to light, text/icons must flip for contrast:
- `MainColors.white` text on dark → `MainColors.dark` text on light
- White icons → dark icons
- Loading indicators (white) → dark
- Placeholder containers can stay dark (they sit behind images)

### Excluded Pages (no background/text changes)

- `lib/presentation/pages/friends_locked_out/` — nav page
- `lib/presentation/pages/manual_lockout/` — lockout timer
- `lib/presentation/pages/lockout_complete/` — celebration
- `lib/presentation/components/nav_overlay/` — hold-to-navigate overlay

---

## 3. Accent Color

**Change:** Subtle warmth shift.

- Current: `#598EB5` (cool muted blue)
- New: `#5A8FB2` — very subtle warm nudge, slightly more saturated
- Single constant change in `MainColors.accent`
- This propagates to all glass tints, CTA themes, and accent usages automatically

---

## 4. Glass on Light Backgrounds

**Problem:** Glass elements designed for dark backgrounds become invisible on white.

**Solution:** Increase tint opacity so glass reads as a subtle frosted blue surface.

### Fallback renderer (`_ShaderGlass` / `_RoundedGlassOverlay`)
- Tint fill alpha: `0.3` → `0.45` (when tint is present)
- Light tint layer (`Colors.white @ 0.08`): reduce or remove — counterproductive on light bg
- Body gradient: flip from white highlights to subtle dark shading
- Edge highlight: reduce white alpha — no longer needed for contrast on dark
- Box shadow: keep but may soften (currently `Color(0x40191919)`)

### Native glass (`UiKitView` / SwiftUI)
- Default opacity for glass configs: bump where needed (e.g., feed lockout button `0.3` → `0.5`)
- Tint colors remain accent-based

### Per-component adjustments
- `GlassVariant.clear` components (date overlay, banners): add accent tint where missing so they don't vanish
- Components already tinted with accent: increase opacity slightly
- All glass should read as "subtle warm-blue frosted surface" against the light background

---

## 5. Color Discipline

**Palette:** Only three core colors plus functional variants.

| Role | Color | Usage |
|------|-------|-------|
| Background | `#F8F7F5` | Page backgrounds, cards |
| Text/Icons | `#1A1A1A` | Primary text, icons on light bg |
| Accent | `#5A8FB2` | Glass tints, interactive elements, CTAs |
| White | `#FFFFFF` | Text on dark surfaces (excluded pages), highlights |
| Error | `#E13748` | Destructive actions, error states |

**Cleanup:**
- Audit every `MainColors.grey*` usage — replace with either surface, dark, or accent as appropriate
- Remove stray hardcoded colors (`Color(0xFF...)` literals) — use MainColors constants
- Ensure no grey-on-grey low-contrast situations

---

## 6. Files Requiring Changes

### Theme layer (propagates everywhere)
- `main_colors.dart` — add surface color, update accent
- `main_theme.dart` — brightness: light, color scheme update
- `call_to_action_style.dart` — borderRadius default
- `call_to_action.dart` — borderRadius parameter
- `app_glass_container.dart` — fallback renderer tint/highlight adjustments
- `glass_config.dart` — possibly default tint behavior

### Pages (~24 page directories, ~90+ files with color refs)
Every non-excluded page's `_page.dart` scaffold background + all `_view.dart` and component files with `MainColors.dark`/`MainColors.white` references.

### Shared components (~15 files)
Alerts, sheets, search bar, form fields, onboarding overlay, mention overlay, share cards, video player.

---

## 7. Consistency Checklist

- [ ] Every non-excluded page has `surface` background
- [ ] Every text element is legible against its background
- [ ] Every glass element is visible on light background
- [ ] Every CTA/button uses `borderRadius: 10`
- [ ] No stray greys or off-brand colors
- [ ] Accent color is consistent everywhere
- [ ] Search bars, chips, badges use 10 radius (not pill)
- [ ] Dialogs, sheets, modals have consistent styling
- [ ] Onboarding/tutorial flow matches new style
