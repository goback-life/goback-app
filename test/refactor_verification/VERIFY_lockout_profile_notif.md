# Verification Report: Lockout, Profile, and Notification Changes

## 1. manual_lockout_notifier_provider.dart (323 -> 280 lines)

### 1a. `_readLockoutState()` extraction

**Evidence:** The diff shows the identical pattern (CheckManualLockoutUseCase -> check isLockedOut -> GetLockoutRemainingTimeUseCase -> build ManualLockoutModel) was present in:
- `build()` (lines removed from original)
- `setLockout()` (17-line "Reload state" block removed)
- `joinLockout()` (17-line "Reload state" block removed)
- `refresh()` (inline check+remaining block removed)

All four now call `_readLockoutState(storable)` which performs the same sequence:
1. `CheckManualLockoutUseCase(storable: storable).execute()`
2. If locked, `GetLockoutRemainingTimeUseCase(storable: storable).execute()`
3. Returns `ManualLockoutModel(isLockedOut: isLockedOut && remainingDuration != null, remainingDuration: remainingDuration)`

The `refresh()` method correctly reads the extracted model's fields (`currentState.isLockedOut`, `currentState.remainingDuration`) and still applies the `isCompletionPending` overlay logic, which was NOT part of the other three call sites. This is correct.

**Verdict: PASS**

### 1b. `_captureBattery()` extraction

**Evidence:** The diff shows the identical try/catch pattern was in:
- `setLockout()`: `int? batteryAtStart; try { batteryAtStart = await Battery().batteryLevel; } catch (_) {}`
- `joinLockout()`: identical block

Both now call `final batteryAtStart = await _captureBattery();` which returns `await Battery().batteryLevel` in a try/catch returning null on failure. Semantically identical.

**Verdict: PASS**

### 1c. Inlined use case constructions

**Evidence:** The diff shows:
- `SetManualLockoutUseCase(...)` was previously assigned to `useCase` then `await useCase.execute()` -- now `await SetManualLockoutUseCase(...).execute()`. Same parameters passed.
- `JoinLockoutUseCase(...)` same pattern. Same parameters passed.
- `GetLockoutRemainingTimeUseCase(...)` in `getRemainingTime()` was assigned to `useCase` then `await useCase.execute()` -- now inlined. Same parameter.

All inlining is strictly equivalent -- same constructors, same arguments, same `.execute()` call.

**Verdict: PASS**

---

## 2. friends_locked_out_cache_provider.dart (152 -> 146 lines)

### `_resetStuckFetch()` extraction

**Evidence:** The diff shows the identical stuck-fetch-reset logic was in two places:

**Original `ensureFresh()`:**
```dart
final fetchStuck = state.isFetching &&
    _fetchStartedAt != null &&
    DateTime.now().difference(_fetchStartedAt!) > _fetchTimeout;
if (fetchStuck) {
  state = state.copyWith(isFetching: false);
  _fetchStartedAt = null;
}
```

**Original `refresh()`:** Identical block.

**New `_resetStuckFetch()`:**
```dart
if (state.isFetching &&
    _fetchStartedAt != null &&
    DateTime.now().difference(_fetchStartedAt!) > _fetchTimeout) {
  state = state.copyWith(isFetching: false);
  _fetchStartedAt = null;
}
```

The only difference is the intermediate `fetchStuck` variable is eliminated by inlining the condition directly in the `if`. Logically identical.

Both `ensureFresh()` and `refresh()` now call `_resetStuckFetch()` as their first statement, preserving original ordering.

**Verdict: PASS**

---

## 3. lockout_session_dto_to_model_mapper.dart - Removed `mapDtoList`

**Evidence:**
- The diff removes only `List<LockoutSessionModel> mapDtoList(List<LockoutSessionDto> dtos) { return dtos.map(mapDto).toList(); }`
- The base class `DtoToModelMapperContract` (at `lib/core/mappers/dto_to_model_mapper_contract.dart`) provides: `List<Model> mapDtoList(List<Dto> dtos) { return dtos.map(mapDto).toList(); }` -- **identical implementation**.
- The override was therefore redundant. The inherited version will be used seamlessly.
- Confirmed: `_mapper.mapDtoList(dtos)` is still called in `friends_locked_out_cache_provider.dart:112` and resolves to the base class method.

**Verdict: PASS**

---

## 4. Profile form hooks refactoring

### 4a. use_create_profile_form.dart (204 -> 97 lines)

### 4b. use_edit_profile_form.dart (251 -> 137 lines)

### 4c. New shared file: profile_form_helpers.dart

**Evidence from `profile_form_helpers.dart`:**

**Shared constants:**
- `const int profileMinUsernameLength = 3;` -- matches original `const int minUsernameLength = 3;` in both files.
- `final RegExp profileUsernameRegex = RegExp(r'^[a-z0-9_\.]+$');` -- matches original `RegExp(r'^[a-z0-9_\.]+$')` in both files.

**Shared `buildProfileFormControls()`:**
Returns a map with three controls:
- `ProfileFormItem.username.value`: FormerControl<String> with `required()`, `minLength(profileMinUsernameLength)`, and custom pattern validator checking `profileUsernameRegex`. Matches original in both hooks.
- `ProfileFormItem.biography.value`: FormerControl<String> with empty validators. Matches original.
- `ProfileFormItem.avatar.value`: FormerControl<File?> with empty validators. Matches original.

**Verdict: PASS**

**Shared `profileFormSubmit()`:**
- Extracts username, biography, avatarFile from values -- same keys and casts as originals.
- `checkUsername` parameter: when true, performs the availability check (same provider call, same fold logic, same early return on failure). In `use_create_profile_form`, always called with `checkUsername: true`. In `use_edit_profile_form`, called with `checkUsername: username != originalUsername.value` -- **matches original edit behavior** which only checked when username differed.
- Avatar upload: same provider call, same error extraction, same early return.
- Profile create/update: same `createOrUpdateProfileProvider` call with same arguments including `biography?.isNotEmpty == true ? biography : null`.
- Return: same fold to `Result.success(true)` / `Result.failure(error)`.

**Verdict: PASS**

**Shared `profileFormOnFailure()`:**
- Logs error with `logger.error('Profile form failed', ...)` -- originals said 'Profile creation failed' and 'Profile update failed' respectively. The log message text changed but this is cosmetic and has no functional impact.
- `CommonSupabaseExceptionUIHandler().handleSupabaseException(...)` -- identical call.
- Switch on error: `ProfileUsernameNotAvailableException` shows same alert with same translation keys. Default shows same `MainAlert.showGenericError`. Identical behavior.

**Verdict: PASS** (minor: log message wording changed, no functional impact)

**Hook-specific behavior preserved:**
- `use_create_profile_form`: `onSuccess` still sets ProfileCompletedStorable, OnboardingCompletedStorable(false), TutorialCompletedStorable(false), then `router.go(HomeRoutable())`. Matches original.
- `use_edit_profile_form`: `onSuccess` still invalidates `getProfileProvider` and pops navigator. Matches original.
- Both hooks still produce the same return typedef shapes (unchanged).
- Both hooks reference `profileMinUsernameLength` for the debounced username check. Matches original `minUsernameLength`.

**Verdict: PASS**

---

## 5. notification_service.dart - Removed `_parseJsonbArray`

**Evidence:**
- The diff removes only the private method `_parseJsonbArray(dynamic value)` (12 lines).
- No other lines in the file were changed.
- Grep for `_parseJsonbArray` across the entire `lib/` directory returns **zero matches**, confirming it was dead code with no call sites.

**Verdict: PASS**

---

## 6. aggregated_notification_dto.dart - Removed `fromRpcJson`

**Evidence:**
- The diff removes only the `factory AggregatedNotificationDto.fromRpcJson(Map<String, dynamic> json)` factory constructor (32 lines).
- The standard `fromJson` factory (generated by json_serializable/freezed) remains intact.
- No other changes to the DTO.
- Grep for `fromRpcJson` across the entire `lib/` directory returns **zero matches**, confirming it was dead code with no call sites.

**Verdict: PASS**

---

## Summary

| # | Change | Verdict |
|---|--------|---------|
| 1a | `_readLockoutState()` extraction (4 call sites) | PASS |
| 1b | `_captureBattery()` extraction (2 call sites) | PASS |
| 1c | Inlined use case constructions | PASS |
| 2 | `_resetStuckFetch()` extraction (2 call sites) | PASS |
| 3 | Removed redundant `mapDtoList` override | PASS |
| 4a | `use_create_profile_form.dart` uses shared helpers | PASS |
| 4b | `use_edit_profile_form.dart` uses shared helpers | PASS |
| 4c | `profile_form_helpers.dart` matches original logic | PASS |
| 5 | Removed dead `_parseJsonbArray` | PASS |
| 6 | Removed dead `fromRpcJson` factory | PASS |

**Overall: ALL PASS -- no behavioral regressions detected.**
