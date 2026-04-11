# Changelog: Supabase + Infrastructure Refactoring

## Files Modified

### `lib/core/features/supabase/data/mixins/supabase_result_processor.dart`
- **242 -> 152 lines** (-37%)
- Inlined `_processResult` into `processSupabaseResult` switch expression
- Inlined `_mapExceptionSafely` into `_handleSupabaseException`
- Renamed private methods for brevity: `_mapFailedResponse` -> `_mapFailure`, `_mapSuccessfulResponse` -> `_mapSuccess`, `_handleUnexpectedException` -> `_wrapUnexpected`, `_extractExceptionMessage` -> `_extractMessage`
- Consolidated 4 Supabase exception type cases into single OR-pattern match
- Removed verbose doc comments that restated parameter names
- Preserved `AuthApiException` rate-limit detection via explicit `is! AuthApiException` guard

### `lib/core/features/crashlytics/data/services/crashlytics_service.dart`
- **138 -> 95 lines** (-31%)
- Extracted `_guard()` helper to deduplicate try/catch/logger.error pattern across 6 methods
- `isCrashlyticsCollectionEnabled()` kept explicit (returns `bool`, not `void`)

### `lib/core/features/crashlytics/utilities/crashlytics_startup_service.dart`
- **104 -> 52 lines** (-50%)
- Removed unused `dynamic crashlyticsService` parameter from `_setupFlutterErrorHandling()` and `_setupDartErrorHandling()` (used `FirebaseCrashlytics.instance` directly)
- Removed unused `dart:async` and `crashlytics_service_provider.dart` imports
- Simplified `_setupDartErrorHandling` null check to `original?.call(...) ?? true`
- Trimmed redundant inline comments

### `lib/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart`
- **93 -> 85 lines** (-9%)
- Removed unused `extra` parameter from private `_showError()` method (never passed by any call site)
- Simplified `_showError` to directly call `translator.translate` inline

### `lib/core/features/crashlytics/domain/contracts/crashlytics_service_contract.dart`
- **63 -> 25 lines** (-60%)
- Removed verbose doc comments (method signatures are self-documenting)

### `lib/core/features/supabase/domain/contracts/common_supabase_exception_ui_handler_contract.dart`
- **26 -> 10 lines** (-62%)
- Trimmed verbose doc comments to concise summary

### `lib/core/features/supabase/domain/contracts/supabase_result_processor_contract.dart`
- **18 -> 12 lines** (-33%)
- Trimmed verbose doc comments

### `lib/core/features/supabase/domain/contracts/supabase_client_service_contract.dart`
- **14 -> 8 lines** (-43%)
- Trimmed verbose doc comments

### `lib/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart`
- **9 -> 5 lines** (-44%)
- Trimmed verbose doc comments

### `lib/core/features/timezone/domain/contracts/timezone_converter_contract.dart`
- **22 -> 12 lines** (-45%)
- Trimmed verbose doc comments, kept ArgumentError documentation

### `lib/core/features/timezone/data/services/timezone_converter.dart`
- **36 -> 21 lines** (-42%)
- Removed class-level doc comment, inlined `tz.getLocation` call

### `lib/core/features/timezone/utilities/timezone_startup_service.dart`
- **19 -> 10 lines** (-47%)
- Trimmed verbose doc comments

### `lib/core/features/supabase/utilities/supabase_startup_service.dart`
- **23 -> 14 lines** (-39%)
- Trimmed verbose doc comments

## Files Added
- `test/refactor_verification/supabase_infra_test.dart` - verification test

## Summary
- **13 files modified**, **1 file added**
- **Total lines saved: ~220 lines** across infrastructure layer
- **No public API changes**
- **No behavioral changes**
- **No new dependencies**
