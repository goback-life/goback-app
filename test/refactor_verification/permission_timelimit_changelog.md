# Changelog: Permission + Time Limit + Share + Onboarding Refactoring

## Summary
Removed dead code and orphaned generated files. No logic or public API changes.

## Changes

### Dead Code Removed
- **Deleted** `lib/core/features/permission/data/exceptions/storage_permission_denied_exception.dart`
  - `StoragePermissionDeniedException` was defined but never imported or used anywhere in the codebase

### Orphaned Generated Files Removed
- **Deleted** `lib/core/features/time_limit/data/providers/time_limit_storable_provider.g.dart`
- **Deleted** `lib/core/features/time_limit/data/providers/time_limit_usage_storable_provider.g.dart`
- **Deleted** `lib/core/features/time_limit/domain/providers/get_time_limit_provider.g.dart`
- **Deleted** `lib/core/features/time_limit/domain/providers/time_limit_notifier_provider.g.dart`
- **Deleted** `lib/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.g.dart`
- **Deleted** empty `lib/core/features/time_limit/` directory tree
  - All 5 files were `.g.dart` generated files whose source `.dart` files no longer exist
  - None of the exported provider symbols were imported anywhere in the codebase

### New Files
- **Added** `test/refactor_verification/permission_timelimit_test.dart` - verification test
- **Added** `test/refactor_verification/permission_timelimit_confidence.md` - confidence analysis
- **Added** `test/refactor_verification/permission_timelimit_changelog.md` - this file

## Files Touched
- 6 files deleted (1 dead exception + 5 orphaned generated files)
- 3 files created (test + analysis + changelog)
- 0 files modified in production code

## Behavior Changes
None. All deleted code was unreachable.

## Not Changed (intentionally preserved)
- Permission exception hierarchy (Camera, Contact, Gallery, CheckStatus, OpenSettings, Rationale, Request)
- Permission enums (PermissionType, PermissionStatus)
- PermissionResultModel and its extensions
- Permission mappers (PermissionStatusMapper, PermissionTypeMapper)
- Permission contracts (PermissionRepositoryContract, PermissionServiceContract)
- Permission service + repository implementations
- Permission providers (check, request, openSettings, shouldShowRationale)
- Permission use cases (all 4)
- Share feature (ShareCardCaptureService, pendingShareProvider)
- Onboarding storables (OnboardingCompletedStorable, TutorialCompletedStorable, TutorialPhaseStorable)
