# Your Circle Page Refactoring Changelog

## Summary
Split two files exceeding the 500-line lint limit. Extracted shared widgets and
deduplicated the repeated avatar pattern in connection request tiles.

## Files Modified

### invite_card_popup.dart (579 -> 248 lines)
- Removed: country code map, phone utility functions, `_ContactsList`, `_ContactRow`, `_InputPill`
- Now imports from `invite_card_contacts.dart`
- No logic changes; all hooks and state management unchanged

### connection_requests_view.dart (568 -> 249 lines)
- Removed: `_SearchResultTile`, `_SmallActionButton`, `_SectionHeader`, `_IncomingRequestTile`, `_OutgoingRequestTile`, `_formatRelativeTime`
- Now imports from `connection_request_tiles.dart`
- No logic changes; search and request handling unchanged

## Files Created

### invite_card_contacts.dart (337 lines)
- Contains: `InviteContactsList`, `InviteContactRow`, `InviteInputPill`
- Contains: `detectCountryFromPhone`, `looksLikePhone`, `isValidPhone`
- Contains: `kCountryCodes` map and shared dimension constants

### connection_request_tiles.dart (332 lines)
- Contains: `ConnectionProfileAvatar` (new, deduplicates 3 avatar patterns)
- Contains: `SmallActionButton`, `RequestSectionHeader`
- Contains: `IncomingRequestTile`, `OutgoingRequestTile`, `SearchResultTile`
- Contains: `formatRelativeTime`

## Files Unchanged
- your_circle_page.dart (127 lines)
- your_circle_view.dart (388 lines)
- your_circle_add_menu.dart (347 lines)
- receive_code_card_popup.dart (395 lines)
- your_circle_friend_tile.dart (193 lines)
- your_circle_remove_dialog.dart (126 lines)
- your_circle_search_pill.dart (65 lines)
- your_circle_layout.dart (39 lines)
- your_circle_routable.dart (33 lines)
- your_circle_invite_button.dart (32 lines)
- your_circle_join_button.dart (34 lines)

## Behavior Changes
None. All changes are structural (file splitting and widget extraction).

## Deduplication
- 3x CircleAvatar+fallback pattern (~60 lines total) consolidated into single
  `ConnectionProfileAvatar` widget (20 lines).

## Verification
- Test file: test/refactor_verification/your_circle_test.dart
- All public APIs verified importable
- All files verified under 500-line lint limit
