# Changelog: Tutorial + Profile Pages Refactoring

## Summary
Split `tutorial_friend_adder.dart` (681 lines, 36% over 500-line limit) into 4 focused files. No changes to any profile, external_profile, circle_profile, or profile_shared files (all already compliant).

## Files Changed

### Modified
- `lib/presentation/pages/tutorial/components/tutorial_friend_adder.dart` (681 -> 176 lines)
  - Removed `_InviteTab` and `_SearchTab` private widget classes
  - Now imports and delegates to `TutorialInviteTab` and `TutorialSearchTab`
  - Retained `TutorialFriendAdder`, `_ProgressRow`, `_TabSwitcher`, `_TabButton`
  - Public API unchanged

### Created
- `lib/presentation/pages/tutorial/components/tutorial_invite_tab.dart` (301 lines)
  - Extracted from `_InviteTab` as public `TutorialInviteTab`
  - Contains `_PhoneInviteRow` and `_ContactRow` helper widgets (extracted from inline builder)
  - Uses shared `TutorialSearchField` instead of inline TextField

- `lib/presentation/pages/tutorial/components/tutorial_search_tab.dart` (187 lines)
  - Extracted from `_SearchTab` as public `TutorialSearchTab`
  - Contains `_SearchResultRow` helper widget (extracted from inline builder)
  - Uses shared `TutorialSearchField` instead of inline TextField

- `lib/presentation/pages/tutorial/components/tutorial_search_field.dart` (60 lines)
  - Shared search TextField widget used by both tabs
  - Consolidates duplicate InputDecoration code from _InviteTab and _SearchTab

- `test/refactor_verification/tutorial_profile_test.dart` (new)
  - Structural verification test covering all tutorial, profile, external_profile, circle_profile, and profile_shared widgets

## Files NOT Changed (verified compliant)
- All profile/ files (max 421 lines - profile_calendar.dart)
- All external_profile/ files (max 89 lines)
- All circle_profile/ files (max 169 lines)
- All profile_shared/ files (max 159 lines)
- All tutorial views/ files (max 187 lines)
- All generated files (.freezed.dart, .g.dart)

## Behavior Changes
None. Pure structural refactoring with widget extraction only.

## Commands to Run
```bash
fvm dart run build_runner build --delete-conflicting-outputs  # Not needed (no model changes)
fvm flutter analyze
fvm flutter test test/refactor_verification/tutorial_profile_test.dart
```
