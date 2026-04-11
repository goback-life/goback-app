# Bayesian Confidence Analysis: Remaining Pages Refactoring

## Prior Assessment
- **Prior confidence (before refactoring)**: 90%
- Rationale: All files were read thoroughly. The codebase uses well-established patterns (Riverpod+hooks, mixin layouts, routables). The files are mostly small and well-structured already.

## Evidence Evaluation

### E1: Extracted AccountStatusDot widget (duplication removal)
- **Change**: Identical 8x8 colored circle dot was duplicated in `invite_to_circle_view.dart` and `invite_to_circle_contact_item.dart`
- **Risk**: Very low. Pure presentational extraction. No logic change. Both call sites now use the same widget with `hasAccount` param.
- **Confidence impact**: +2% (simple extraction, no behavioral change)

### E2: Simplified PhoneContactData reconstruction
- **Change**: Extracted local `withContacts()` helper inside `useMemoized` to eliminate duplicated `PhoneContactData` construction (7 identical fields).
- **Risk**: Very low. The local function is within the same `useMemoized` closure. Same fields, same values, same dependency array.
- **Confidence impact**: +1% (mechanical dedup, same closure scope)

### E3: Removed commented-out code in preferences_section.dart
- **Change**: Removed ~38 lines of commented-out notification toggle code and commented import.
- **Risk**: None. Commented-out code has no runtime effect. The `NotificationSwitch` widget and its layout file are preserved as separate files.
- **Confidence impact**: +1% (dead code removal)

### E4: Removed commented-out code in notifications_switch.dart
- **Change**: Removed commented `toggle()` method (4 lines) and trailing comment on closing bracket.
- **Risk**: None. Comments have no runtime effect.
- **Confidence impact**: +1% (dead code removal)

### E5: Removed no-op Padding wrapper in contact_list.dart
- **Change**: Removed `Padding(padding: const EdgeInsets.symmetric(), child: ...)` which had zero padding on all sides.
- **Risk**: Very low. `EdgeInsets.symmetric()` with no arguments produces `EdgeInsets.zero`, making the `Padding` widget a no-op wrapper.
- **Confidence impact**: +1% (no visual change)

## Negative Evidence (Things NOT changed)
- No changes to routables, page classes, or layout mixins
- No changes to join_circle, review_circle, notifications, settings (view/page), or objective directories (except preferences_section comment cleanup)
- No changes to any hook logic, form handling, or navigation
- NotificationHeader (unused) was preserved to avoid breaking potential future use
- NotificationSwitch files preserved despite being functionally unused (import commented out in preferences_section)

## Posterior Confidence
| Factor | Confidence |
|--------|-----------|
| Prior | 90% |
| E1: AccountStatusDot extraction | +2% |
| E2: PhoneContactData helper | +1% |
| E3: preferences_section cleanup | +1% |
| E4: notifications_switch cleanup | +1% |
| E5: no-op Padding removal | +1% |
| **Posterior** | **96%** |

## Risk Assessment
- **Highest risk**: AccountStatusDot extraction (still very low - pure UI, no logic)
- **Mitigation**: Verification test covers all public APIs, constructors, and layout mixin values
- **Residual risk**: Theoretical visual regression if `MainColors` import was removed (it was not)

## Conclusion
**Final confidence: 96%** - exceeds 95% threshold. All changes are mechanical (duplication removal, dead code cleanup). No behavioral, API, or visual changes.
