# In-App Forced Update Prompt

**Date:** 2026-04-14
**Status:** Approved

## Summary

Add a blocking in-app update dialog using the `upgrader` Flutter package. When a newer version is available on the App Store, the user must update before they can continue using the app.

## Behavior

- On app launch (and resume), `upgrader` checks the App Store for a newer version
- If a newer version exists, a non-dismissable dialog appears with a single "Update Now" button
- "Update Now" opens the App Store listing for the app
- The user cannot dismiss the dialog by tapping outside, pressing back, or any other means
- The dialog appears regardless of auth state or navigation position

## Integration Point

The `UpgradeAlert` widget wraps the app content inside `appBuilder` in `startup_config.dart`:

```
NavOverlayWrapper
  └── LockoutListenerWidget
      └── UpgradeAlert (showIgnore: false, showLater: false, canDismissDialog: false)
          └── child (router/navigation)
```

## Configuration

| Property | Value | Reason |
|----------|-------|--------|
| `showIgnore` | `false` | No option to permanently dismiss |
| `showLater` | `false` | No option to defer |
| `canDismissDialog` | `false` | Cannot tap outside to dismiss |
| `showReleaseNotes` | `false` | Keep dialog simple |

## Files Changed

1. **`pubspec.yaml`** — add `upgrader` dependency
2. **`lib/core/features/startup/data/config/startup_config.dart`** — wrap child in `UpgradeAlert`

## Out of Scope

- Custom dialog UI (using upgrader's default dialog)
- Server-side minimum version control (can be layered on later)
- Android-specific in-app update API integration
