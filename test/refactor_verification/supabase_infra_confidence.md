# Bayesian Confidence Analysis: Supabase + Infrastructure Refactoring

## Prior: P(no regression) = 0.90
Infrastructure code is foundational. Changes carry higher baseline risk due to the number of downstream consumers.

## Evidence Factors

### E1: Scope of changes is minimal (+4%)
- Changes are limited to: comment trimming, dead code removal, helper extraction, unused parameter removal
- No new files, no new abstractions, no structural changes
- All changes are internal (private methods, doc comments, unused parameters)

### E2: Public API surface preserved (+3%)
- All contract interfaces (`SupabaseResultProcessorContract`, `CrashlyticsServiceContract`, `CommonSupabaseExceptionUIHandlerContract`, etc.) have identical method signatures
- `SupabaseResultProcessor.processSupabaseResult()` signature unchanged
- `CrashlyticsService` implements same contract with same method signatures
- `CrashlyticsStartupService.initialize(WidgetRef ref)` signature preserved (ref param kept for backward compatibility despite being unused)
- All class hierarchies unchanged (implements/extends relationships)

### E3: Exception mapping behavior preserved (+2%)
- `_mapFailure` (was `_mapFailedResponse`) matches same error types in same order
- Critical: `AuthApiException` rate-limit handling explicitly preserved with `is! AuthApiException` guard
- All Supabase exception types (AuthException, AuthApiException, PostgrestException, StorageException) routed identically
- Network error detection (SocketException in message, failed host lookup) unchanged
- Rate limit pattern set unchanged (8 patterns)

### E4: Helper extraction is behavior-preserving (+2%)
- `CrashlyticsService._guard()` wraps same try/catch/logger.error pattern
- `_processResult` inlined into switch expression in `processSupabaseResult` - exact same branching
- `_mapExceptionSafely` inlined into `_handleSupabaseException` - same try/catch/UnhandledException

### E5: Dead code removal verified safe (+1%)
- `crashlytics_startup_service.dart`: `crashlyticsService` parameter was truly unused in both `_setupFlutterErrorHandling` and `_setupDartErrorHandling` (they used `FirebaseCrashlytics.instance` directly)
- `_showError.extra` parameter: all 4 call sites confirmed to never pass `extra`
- Removed `crashlytics_service_provider.dart` import from startup service since provider is no longer read

### E6: No downstream breakage (-1%)
- 5 repositories mix in `SupabaseResultProcessor` - they call `processSupabaseResult` which has same signature
- 6 hooks/forms use `CommonSupabaseExceptionUIHandler` - `handleSupabaseException` signature unchanged
- `main.dart` calls `CrashlyticsStartupService.initialize(ref)` - signature preserved
- Minor risk: `_setupDartErrorHandling` simplified to `original?.call(error, stackTrace) ?? true` from explicit null check - semantically identical

## Posterior: P(no regression) = 0.90 + 0.04 + 0.03 + 0.02 + 0.02 + 0.01 - 0.01 = **0.96 (96%)**

## Confidence: PASS (>95%)

## Risk Mitigation
- Verification test (`supabase_infra_test.dart`) validates all key contracts and behaviors
- TimezoneConverter tests verify UTC conversion with real timezone data
- Exception hierarchy tests verify all exception types and their relationships
