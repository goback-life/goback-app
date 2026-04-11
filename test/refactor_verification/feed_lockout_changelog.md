# Feed + Lockout Pages Refactoring Changelog

## Summary
Extracted shared code from lockout pages to eliminate duplication and bring `manual_lockout_view.dart` (513 lines) below the 500-line lint limit.

## Changes

### New Files
1. **`lib/presentation/pages/manual_lockout/components/lockout_cutout_painter.dart`** (232 lines)
   - Extracted `LockoutCutoutPainter` (was `_CutoutPainter` in manual_lockout_view.dart)
   - Extracted `lockoutTrianglePath()` (was `_trianglePath` duplicated in 2 files)

2. **`lib/presentation/pages/manual_lockout/components/lockout_lifecycle_observer.dart`** (15 lines)
   - Extracted `LockoutLifecycleObserver` (was `_LifecycleObserver` duplicated in 3 files)

### Modified Files
3. **`lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`** (513 -> 297 lines)
   - Removed `_CutoutPainter` class and `_trianglePath` function (extracted to lockout_cutout_painter.dart)
   - Added import for `lockout_cutout_painter.dart`
   - Removed unused `main_font_families.dart` import
   - Updated `_CutoutPainter` reference to `LockoutCutoutPainter`
   - Updated comment reference from `_CutoutPainter` to `LockoutCutoutPainter`

4. **`lib/presentation/pages/feed/components/feed_lockout_button.dart`** (344 -> 316 lines)
   - Removed private `_trianglePath` function (now uses shared `lockoutTrianglePath`)
   - Added import for `lockout_cutout_painter.dart`

5. **`lib/presentation/pages/manual_lockout/components/lockout_friends_overlay.dart`** (309 -> 299 lines)
   - Removed private `_LifecycleObserver` class (now uses shared `LockoutLifecycleObserver`)
   - Added import for `lockout_lifecycle_observer.dart`
   - Fixed import ordering (moved `dart:ui` to top per convention)

6. **`lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart`** (240 -> 230 lines)
   - Removed private `_LifecycleObserver` class (now uses shared `LockoutLifecycleObserver`)
   - Added import for `lockout_lifecycle_observer.dart`

7. **`lib/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart`** (283 -> 274 lines)
   - Removed private `_LifecycleObserver` class (now uses shared `LockoutLifecycleObserver`)
   - Added import for `lockout_lifecycle_observer.dart`

### Test Files
8. **`test/refactor_verification/feed_lockout_test.dart`** (new)
   - Verification tests documenting FeedLayout constants, triangle path contract, time formatting, and widget public API contracts.

## Behavior Changes
None. All changes are purely structural (extract + import). No logic, parameters, or public APIs were modified.

## Duplication Eliminated
- Triangle path: 2 copies -> 1 shared function
- LifecycleObserver: 3 copies -> 1 shared class
- CutoutPainter: extracted from 513-line file to dedicated component

## Net Line Impact
- Lines removed from existing files: ~267
- Lines added in new files: ~247
- Net change: -20 lines (slight reduction through deduplication)
