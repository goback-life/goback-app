# Profile Page iOS Crash Fix — 2026-02-27

Commit: `d66b7c4` on branch `lockv1`

## Problem

Opening the profile page frequently crashed the iOS app due to GPU memory
pressure and a Flutter hooks violation.

## Root Causes Identified

1. **BackdropFilter overload in calendar grid** — Each empty calendar day cell
   rendered an `AppGlassContainer` containing a `BackdropFilter` with
   `ImageFilter.compose` (blur + matrix). With ~30 empty days per month, this
   created ~30 simultaneous GPU-heavy blur operations, exhausting iOS GPU memory.

2. **Hook ordering violation in ProfileDescription** — `useMemoized` was called
   inside `_buildDescriptionDisplay()`, which only ran after async data resolved.
   During loading/error states the hook was skipped, violating the Flutter Hooks
   contract (hooks must run in the same order every build).

3. **Missing error handling on calendar thumbnails** — `CachedNetworkImage` in
   calendar day cells had no `placeholder` or `errorWidget`.

4. **Redundant provider watches** — Five widgets on the profile page each
   independently watched `getCurrentUserProvider` + `getProfileProvider`,
   causing ~10 cascading rebuilds when data loaded.

## Changes Made

### 1. `lib/presentation/pages/profile/components/calendar_section/calendar_day.dart`

**Before:** Empty day cells used `AppGlassContainer` with `GlassConfig(variant: GlassVariant.regular)`.

**After:** Replaced with `ClipPath(clipper: SquircleClipper())` + `Container` with
`Colors.white.withValues(alpha: 0.08)`. Same visual appearance, no BackdropFilter.

Also added `placeholder` and `errorWidget` to `CachedNetworkImage` for thumbnail cells.

Removed imports: `app_glass_container.dart`, `glass_config.dart`.

### 2. `lib/presentation/components/profile_description.dart`

**Before:** `build()` resolved async state via nested `when()` callbacks, each
eventually calling `_buildDescriptionDisplay()` which contained `useMemoized`.
The hook was never called during loading/error states.

**After:** `build()` resolves biography into local variables (`resolvedBio`,
`isLoading`, `isError`) first, then calls `useMemoized` unconditionally before
returning the appropriate widget. Removed `_buildDescriptionDisplay()` helper.

### 3. `lib/presentation/pages/profile/views/profile_view.dart`

**Before:** `StatelessWidget` that created child widgets with no props — each
child independently watched `getCurrentUserProvider` + `getProfileProvider`.

**After:** `ConsumerWidget` that watches both providers once, extracts
`avatarUrl`, `username`, `biography`, `weeklyLockoutMinutes`, then passes them
to children via existing constructor parameters. Falls back to the original
self-resolving behavior while loading.

### 4. `lib/presentation/pages/profile/components/profile_weekly_stats.dart`

**Before:** `const ProfileWeeklyStats()` with no parameters — always watched
providers internally.

**After:** Added optional `weeklyLockoutMinutes` and `hasResolvedData` params.
When `hasResolvedData: true`, skips provider watches and uses the passed value.
Backwards compatible — defaults to `false` so existing call sites (e.g.
`circle_profile_view.dart`) are unaffected.

## Rollback

To revert all changes:

```bash
git revert d66b7c4
```

Or to restore individual files to their pre-fix state:

```bash
git checkout d66b7c4^ -- lib/presentation/pages/profile/components/calendar_section/calendar_day.dart
git checkout d66b7c4^ -- lib/presentation/components/profile_description.dart
git checkout d66b7c4^ -- lib/presentation/pages/profile/views/profile_view.dart
git checkout d66b7c4^ -- lib/presentation/pages/profile/components/profile_weekly_stats.dart
```
