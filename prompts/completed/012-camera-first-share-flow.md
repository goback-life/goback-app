<objective>
Implement a custom Snapchat-style camera page for the lockout share flow. When a user taps "Share your goback" after their lockout timer reaches 0:00, a full-screen camera opens instantly. Tap shutter for photo, hold for video. Gallery thumbnail in bottom-left. After capture, proceed to the content editor (optional caption) and publish directly to the full circle (no member selection for lockout posts).

Flow: "Share your goback" -> Custom camera page -> Content editor (optional caption) -> Posted to full circle.
</objective>

<context>
After a lockout ends, the user sees "Share your goback" or "Skip" on the lockout screen. The current share flow shows 2-3 bottom sheets (content type, media type, source) before reaching the camera. This kills the impulse to share. We are replacing this with a single custom camera page that handles everything.

Design reference: Snapchat camera — full-screen viewfinder, large circular shutter button (tap = photo, hold = video with progress ring), small gallery thumbnail in bottom-left corner, flip camera button in top-right.

Current entry point in `manual_lockout_view.dart`:
```dart
void _handleShare(WidgetRef ref, String lockoutSessionId, PostCreationInitializationResult postCreationInit) {
  if (lockoutSessionId.isNotEmpty) {
    ref.read(pendingLockoutPostProvider.notifier).setLockoutId(lockoutSessionId);
  }
  postCreationInit.selectMainImage(); // <-- triggers picker sheets (to be replaced)
}
```

Existing infrastructure that MUST be reused (do not rewrite):
- `PostCreationNotifier` / `postCreationNotifierProvider` — state management for post creation
- `ContentEditorPage` / `ContentEditorRoutable` — description editing screen
- `usePostCreation` / `publishPostWithExclusions()` — publishing logic with lockout guard + auto-tagging
- `pendingLockoutPostProvider` — links posts to lockout sessions
- `VideoThumbnailHelper.extractThumbnail()` — extracts first frame for video thumbnail
- `PermissionType.camera` / `requestPermissionProvider` — permission handling
- `usePickAndCompressImageWithPermission` — image compression after capture (for photos)

@CLAUDE.md for coding patterns
</context>

<research>
Before implementing, examine these files to understand the patterns to follow:
1. `lib/core/features/media/domain/hooks/use_media_picker.dart` — current picker orchestration, `_handlePhotoSelection` and `_handleVideoSelection` logic, video duration validation (60s max)
2. `lib/core/features/post/domain/hooks/use_post_creation_initialization.dart` — the `onMediaSelected` callback that updates `PostCreationNotifier` and navigates to `ContentEditorRoutable`
3. `lib/core/features/media/domain/hooks/use_pick_and_compress_image_with_permission.dart` — permission handling with retry + settings redirect
4. `lib/core/features/post/domain/hooks/use_post_creation.dart` — `publishPostWithExclusions()`, lockout guard (lines ~91-99), auto-tagging (lines ~125-153)
5. `lib/presentation/pages/content_editor/components/content_editor_button.dart` — the "Next" button that navigates to `PublishContentRoutable` (needs lockout bypass)
6. `lib/core/features/permission/domain/enums/permission_type.dart` — existing permission types (camera, gallery)
7. `lib/core/features/post/domain/providers/post_creation_notifier_provider.dart` — state updates: `updateImage()`, `updateFirstFrame()`, `updateContentType()`
8. `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart` — current `_handleShare` entry point
9. `pubspec.yaml` — check if `camera` package already exists (it does not; `image_picker: ^1.2.0` is present)
</research>

<requirements>

## Change 1: Add `camera` package dependency

Add `camera: ^0.11.0` to `pubspec.yaml`. This provides the low-level camera controller needed for a custom camera UI with tap-for-photo / hold-for-video.

Also add `photo_manager: ^3.6.0` for fetching the most recent gallery thumbnail (the small preview in the bottom-left corner). If `photo_manager` is too heavy or causes issues, fall back to a static gallery icon instead.

## Change 2: Create the custom camera page

Create `lib/presentation/pages/camera_capture/` with:

### Route: `camera_capture_routable.dart`
Standard Freezed Routable class with path `/camera-capture`. No middlewares needed (the lockout share flow handles auth).

### Page: `camera_capture_page.dart`
Scaffold with transparent background, no app bar. Hosts `CameraCaptureView`.

### View: `camera_capture_view.dart` (HookConsumerWidget)
Full-screen camera viewfinder with these elements:

**Camera preview**: Full-screen `CameraPreview` widget from the `camera` package. Initialize with back camera, `ResolutionPreset.high`.

**Shutter button** (bottom center): Large circular button (72px diameter).
- Tap → capture photo via `controller.takePicture()`
- Long-press → start video recording via `controller.startVideoRecording()`. Show a circular progress ring around the button that fills over 60 seconds (max video duration). Release or timeout → `controller.stopVideoRecording()`.
- Visual feedback: scale animation on press, progress ring during video recording.

**Gallery thumbnail** (bottom-left): Small rounded square (48px) showing the most recent photo from the device gallery. Tap opens `ImagePicker().pickImage(source: ImageSource.gallery)` or `ImagePicker().pickVideo(source: ImageSource.gallery)` (offer both via a quick sheet, or just pick image and auto-detect). If fetching the thumbnail fails, show a generic gallery icon.

**Flip camera button** (top-right): Toggles between front and back camera via `controller.setDescription()`.

**Close button** (top-left): X button that pops back to the lockout screen.

**After capture**: Call the `onMediaCaptured(File file)` callback passed to the page. This callback (provided by the parent) handles updating `PostCreationNotifier` and navigating to the content editor — reusing the same logic from `use_post_creation_initialization.dart`'s `onMediaSelected`.

**Permissions**: On mount, check camera permission via existing `requestPermissionProvider(type: PermissionType.camera)`. If denied, show the same alert flow as `use_pick_and_compress_image_with_permission.dart` (retry or open settings). For video, also request microphone permission.

**Lifecycle**: Dispose camera controller properly. Handle app pause/resume (stop preview on pause, restart on resume).

## Change 3: Wire the lockout share flow to the new camera page

In `manual_lockout_view.dart`, replace the current `_handleShare` method:

**Before**: Sets `pendingLockoutPostProvider`, then calls `postCreationInit.selectMainImage()` which triggers picker sheets.

**After**: Sets `pendingLockoutPostProvider`, then navigates directly to the new `CameraCaptureRoutable()`. Pass a callback that handles the captured file the same way `use_post_creation_initialization.dart`'s `onMediaSelected` does:
1. Detect photo vs video from file extension
2. Update `PostCreationNotifier` (image, content type, first frame for videos)
3. Navigate to `ContentEditorRoutable`

This means the lockout flow bypasses `usePostCreationInitialization` and `useMediaPicker` entirely — those hooks remain unchanged for the normal (non-lockout) post creation flow.

## Change 4: Skip publish screen for lockout posts

In `content_editor_button.dart`, detect lockout mode by reading `pendingLockoutPostProvider`. When it has a value:
- Change button label from the translated "Next" text to "Post"
- Instead of `router.push(const PublishContentRoutable())`, call `publishPostWithExclusions([])` directly (empty exclusions = share with everyone in circle)
- Show a loading indicator during publish
- On success, the `usePostCreation` hook already navigates to `HomeRoutable` and clears lockout state

This requires the button to become a `HookConsumerWidget` (it already is) and to use the `usePostCreation` hook or read the relevant providers.

## Files to create

```
lib/presentation/pages/camera_capture/camera_capture_routable.dart  — route definition
lib/presentation/pages/camera_capture/camera_capture_page.dart      — page scaffold
lib/presentation/pages/camera_capture/views/camera_capture_view.dart — camera UI + logic
```

## Files to modify

```
pubspec.yaml                                                         — add camera + photo_manager deps
lib/presentation/routes.dart                                         — register CameraCaptureRoutable
lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart — navigate to camera instead of picker sheets
lib/presentation/pages/content_editor/components/content_editor_button.dart — skip publish screen in lockout mode
```

## Files NOT to modify (keep existing flows intact)

```
lib/core/features/media/domain/hooks/use_media_picker.dart                    — unchanged, used by non-lockout flows
lib/core/features/post/domain/hooks/use_post_creation_initialization.dart     — unchanged
lib/core/features/post/domain/hooks/use_post_creation.dart                    — unchanged, reused by lockout publish
```

</requirements>

<verification>
After implementation, verify:

1. **Camera page**
   - [ ] "Share your goback" opens full-screen camera instantly (no sheets)
   - [ ] Camera preview displays correctly (back camera default)
   - [ ] Flip button switches between front and back camera
   - [ ] Close button returns to lockout screen
   - [ ] Camera permission requested and handled (deny → alert → settings)

2. **Photo capture**
   - [ ] Tap shutter takes a photo
   - [ ] Photo navigates to content editor with image displayed
   - [ ] Image is compressed appropriately

3. **Video capture**
   - [ ] Long-press shutter starts video recording
   - [ ] Progress ring animates around shutter button
   - [ ] Release stops recording and navigates to content editor
   - [ ] Video auto-stops at 60 seconds max
   - [ ] First frame thumbnail extracted for video posts
   - [ ] Microphone permission requested for video

4. **Gallery access**
   - [ ] Gallery thumbnail visible in bottom-left corner
   - [ ] Tapping thumbnail opens gallery picker
   - [ ] Selected photo/video proceeds to content editor
   - [ ] Auto-detect photo vs video from file extension

5. **Content editor + direct publish**
   - [ ] Description field present but optional
   - [ ] Button says "Post" (not "Next") in lockout mode
   - [ ] Tapping "Post" publishes directly to full circle (no member selection)
   - [ ] Post linked to lockout session, participants auto-tagged
   - [ ] After publish, navigates to home and clears lockout state

6. **Non-lockout flows unaffected**
   - [ ] Normal post creation (from feed) still uses picker sheets as before
   - [ ] Publish screen still appears for non-lockout posts

7. **Edge cases**
   - [ ] App pause/resume during camera preview (no crash)
   - [ ] Camera permission permanently denied → opens settings
   - [ ] No available cameras (graceful error)
   - [ ] Cancel at any step returns cleanly (no stuck state, no leaked NotifierProvider state)
</verification>

<notes>
- The `camera` package requires minimum iOS 12 and Android API 21. Verify these match the project's min SDK versions.
- The `camera` package needs `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` in Info.plist — check if these already exist from `image_picker`.
- Video compression is NOT in scope. Raw video files go through as-is (existing behavior from `use_media_picker.dart`'s `_handleVideoSelection`).
- The gallery thumbnail in the bottom-left should use `photo_manager` to fetch the last image from the device. If this causes permission complexity, use a simple gallery icon (like a grid/photo icon) instead.
- Keep the custom camera page general-purpose (not lockout-specific) so it can be reused for normal post creation in the future.
- Dispose the camera controller in the widget's dispose/deactivate to prevent memory leaks.
- The shutter button long-press UX: consider haptic feedback on recording start/stop.
</notes>
