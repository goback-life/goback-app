# Session Changelog — 2026-02-27

## Summary

Fixed iOS glass button tap failures, animation issues, nav overlay blur, lockout UI bugs, and bottom sheet coverage gaps.

---

## Changes by file

### `lib/presentation/pages/your_circle/components/your_circle_add_menu.dart`
- **Fix**: Added `behavior: HitTestBehavior.opaque` to all 3 `GestureDetector` instances (plus button, up arrow, down arrow) so taps register on glass buttons
- **Fix**: Replaced rotation animation (broke on iOS 26+ native glass) with scale-down + subtle glow animation
- Removed `dart:math` import, added `dart:ui` import
- Changed `SingleTickerProviderStateMixin` to `TickerProviderStateMixin`
- Added `_glowController` + `_PlusGlowPainter` matching feed lockout button style (barely noticeable edge highlight + caustic)

### `lib/presentation/components/nav_overlay/nav_overlay_wrapper.dart`
- **Fix**: Wrapped child in `ImageFiltered(blur: 30)` when overlay is visible, so blur works even when dialogs/popups are open (BackdropFilter can't blur across compositing boundaries)
- Added `dart:ui` import

### `lib/presentation/components/nav_overlay/nav_overlay.dart`
- Removed `BackdropFilter` wrapper (blur now handled by wrapper's `ImageFiltered`)
- Increased dark overlay alpha from 0.5 to 0.88 to cover native platform views that can't be blurred by Flutter
- Removed unused `dart:ui` import

### `lib/presentation/pages/home/components/manual_lockout_dialog.dart`
- **Fix**: Removed explicit text style from lockout confirm button label — was setting `color: colorScheme.primary` which matched the glass tint, making text invisible. CTA theme system now handles colors correctly.

### `lib/presentation/pages/circle_profile/circle_profile_page.dart`
- **Feature**: Added back button (top-left arrow) with `router.pop()`, positioned symmetrically with hamburger menu

### `lib/presentation/pages/manual_lockout/components/lockout_friends_overlay.dart`
- **Fix**: Replaced `AppGlassContainer` with direct `SizedBox.expand` + `ClipRect` + `BackdropFilter(blur: 15)` + `ColoredBox(white @ 0.12)` so the frosted overlay covers the entire screen including the bottom
- **Fix**: Hardcoded text color to `MainColors.dark` (black) instead of computing from surface luminance
- Added `SafeArea(bottom: false)` so content respects top safe area but glass fills to bottom edge

### `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`
- Wrapped `LockoutFriendsOverlay` in `Positioned.fill` for explicit full-screen positioning in the Stack

### `lib/presentation/components/sheets/media_type_picker_sheet.dart`
- **Fix**: Replaced `AppGlassContainer` with solid `Container(color: colorScheme.surface)` using `BorderRadius.vertical(top:)` so the sheet background extends fully to the bottom of the screen (matching `MediaSourcePickerSheet`)
- Removed glass imports

### `lib/presentation/pages/feed/components/feed_posts_list.dart`
- **Fix**: Added `mountedRef.value` guard before `onTopPostDateChanged` callback in `addPostFrameCallback`, preventing `ValueNotifier<DateTime?>` used-after-disposed crash on hot refresh

---

## Files NOT changed (unrelated to this session)

These were already modified before this session:
- `assets/images/fonts/icons.otf`
- `ios/Podfile.lock`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/stage.xcscheme`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `pubspec.yaml`

---

## How to revert

To revert all session changes while keeping pre-existing modifications:

```bash
git checkout HEAD -- \
  lib/presentation/components/nav_overlay/nav_overlay.dart \
  lib/presentation/components/nav_overlay/nav_overlay_wrapper.dart \
  lib/presentation/components/sheets/media_type_picker_sheet.dart \
  lib/presentation/pages/circle_profile/circle_profile_page.dart \
  lib/presentation/pages/feed/components/feed_posts_list.dart \
  lib/presentation/pages/home/components/manual_lockout_dialog.dart \
  lib/presentation/pages/manual_lockout/components/lockout_friends_overlay.dart \
  lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart \
  lib/presentation/pages/your_circle/components/your_circle_add_menu.dart
```
