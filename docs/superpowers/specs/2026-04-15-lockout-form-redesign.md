# Lockout Form Redesign — Apple-Inspired Bottom Sheet

**Status:** Draft
**Date:** 2026-04-15

## Problem

The current lockout form is a centered dialog packed with too many elements: title, NFC button, divider, description text, two side-by-side Cupertino pickers (hours + minutes), 5 activity chips, a custom text field with character counter, validation error, and confirm button. It feels cluttered and utilitarian.

## Design

Replace the dialog with a bottom sheet featuring a drag-to-set clock ring, streamlined activity selection, and the app's glassmorphism language.

### Container: Glass Bottom Sheet

- Slides up from the bottom over a dimmed scrim (`rgba(10,10,10,0.5)`)
- Glass surface: `#1A1A1A` at 85% opacity, 40px blur, white gradient overlay (NW→SE: `rgba(255,255,255,0.08)` → `rgba(255,255,255,0.02)`), top edge highlight
- Corner radius: 24px (top-left, top-right only)
- Drag handle at top (36x4, `rgba(255,255,255,0.2)`)
- Dismissible by dragging down or tapping scrim

### Duration: Sky-Filled Drag Ring

- Circular ring centered in the sheet, ~220pt diameter
- **Range:** 30 minutes → 10 hours (requires DB migration: min lockout 60→30 min for non-NFC)
- **Inactive track:** Glass-gradient stroke (`rgba(255,255,255,0.07)` → `rgba(255,255,255,0.03)`), 14pt width
- **Active arc:** Filled with `background_goback.png` sky/cloud image, clipped strictly to the arc stroke via `ImageShader` on `Canvas.drawArc`. Only the coloured segment shows the sky.
- **Glow:** Subtle blue glow (`#5BA3D9`, opacity 0.1, 4px gaussian blur) behind the active arc
- **Thumb:** 15pt radius circle, sky-blue (`#5BA3D9`) with radial white-to-transparent gradient sheen and 1px white border at 20% opacity
- **Snapping:** Snaps to 30-minute increments. Fine-grain: user can slow-drag for 15-minute precision.
- **Hour tick marks:** 4 ticks at 12/3/6/9 positions, white at 18% opacity, 1.5pt stroke
- **Glass disc interior:** The area inside the ring is a frosted glass circle (3% white, 20px blur, gradient overlay, 1px border at 6% opacity)
- **Center display:** Duration in large thin text (48pt, weight 200, tabular-nums, -2px letter-spacing) with "hours" or "minutes" label below (12pt, 35% opacity)
- **Clockwise from top:** 12 o'clock = 0, dragging clockwise increases duration. Full rotation = 10 hours.
- **Initial state:** Sheet opens with thumb at 1 hour (matching current default). Arc shows sky for the 1hr segment.
- **Minimum enforcement:** Thumb cannot be dragged below 30 minutes. Below-minimum range is visually dead (no arc renders for positions < 30min).

### Activity Selection: Square Chips with Line Icons

- Horizontal wrapping row of square-cornered chips (10px border-radius)
- Fixed-width chips (~72-82pt wide, 42pt tall) with centered icon + label
- **Icons:** SVG line-stroke style (Feather/Lucide), 16x16, stroke-width 2, round caps
  - Sport: running figure
  - Music: music notes
  - Friends: two people
  - Relax: leaf
  - Study: book
  - Custom: pencil (icon-only, 42x42 square)
- **Unselected state:** `rgba(255,255,255,0.04)` background, 1px border at `rgba(255,255,255,0.08)`, icon/text at 50% white
- **Selected state:** `rgba(89,142,181,0.15)` background, 1.5px border at `rgba(89,142,181,0.45)`, icon/text in `#598EB5`
- **Selection is optional** — user can start a lockout without picking an activity
- **Single-select** — tapping a selected chip deselects it

### Custom Activity: Chip-to-TextField Morph

- Tapping the pencil chip morphs it into an inline text field (~140pt wide)
- The chip animates: width expands, pencil icon stays as a leading icon, cursor appears
- Max 20 characters, no character counter visible (just silently caps)
- Clearing the text or tapping away collapses it back to the pencil-only chip
- When custom text is entered, all preset chips are deselected
- When a preset chip is tapped, the custom field collapses and clears

### CTA: "Go Back" Button

- Full-width, 16px border-radius, 16px vertical padding
- Solid `#598EB5` background with glass gradient sheen (white 15%→0% at 135deg)
- Text: "Go Back", 17pt, weight 600, 0.3px letter-spacing, white
- Disabled state when duration < 30 min (reduced opacity, no tap)

### NFC: Subtle Text Link

- Below the CTA: "At a venue? **Scan Tag**"
- 14pt, body text at 35% white opacity, "Scan Tag" in `#598EB5` at weight 500
- Tapping "Scan Tag" dismisses the sheet and returns `nfcScan: true` (same as current)

### Title

- "GO BACK" — 13pt, weight 600, 1.2px letter-spacing, uppercase, 45% white opacity
- Below the drag handle, above the ring

## Data Changes

### DB Migration: Minimum lockout duration

- Update the `lockout_duration_constraints` check constraint (or equivalent) to allow minimum 30 minutes for non-NFC lockouts (currently 60 minutes)
- The `MIN_LOCKOUT_MINUTES` dart-define default changes from 60 → 30

### Return Type (unchanged)

```dart
({Duration? duration, String? actionText, bool nfcScan})?
```

The bottom sheet returns the same type as the current dialog. No changes to the provider, service, or storable layers.

## Scope Boundaries

**In scope:**
- Replace `ManualLockoutDialog` with a new bottom sheet widget
- Implement the drag ring with sky-image arc fill
- Square activity chips with line icons
- Custom chip morph animation
- DB migration for 30-min minimum
- Update `MIN_LOCKOUT_MINUTES` default

**Out of scope:**
- Changes to the lockout timer screen itself
- Changes to the lockout completion flow
- Changes to the GoBack score calculation
- NFC scan flow changes (just re-routed from the new sheet)
- Post-lockout sharing flow
