# Notification Feature Refactoring Changelog

## Summary
Conservative dead code removal in the notification feature. Two unused private methods removed. No public API changes, no logic changes, no behavioral changes.

## Changes

### 1. Removed dead `_parseJsonbArray` method from NotificationService
- **File**: `lib/core/features/notification/data/services/notification_service.dart`
- **What**: Removed private `_parseJsonbArray(dynamic value)` method (10 lines)
- **Why**: Zero call sites. The service builds `AggregatedNotificationDto` manually in `getAggregatedNotifications()` without using this helper. A similar function existed inline in `AggregatedNotificationDto.fromRpcJson` (also removed).
- **Risk**: None. Private method with no callers.

### 2. Removed dead `fromRpcJson` factory from AggregatedNotificationDto
- **File**: `lib/core/features/notification/data/dtos/aggregated_notification_dto.dart`
- **What**: Removed `factory AggregatedNotificationDto.fromRpcJson(Map<String, dynamic> json)` (30 lines)
- **Why**: Zero call sites in the entire codebase. `NotificationService` constructs DTOs directly using the default constructor with manual field mapping, never calling this factory.
- **Risk**: None. Unused factory with no callers.

## Files Touched
1. `lib/core/features/notification/data/services/notification_service.dart` (removed 10 lines)
2. `lib/core/features/notification/data/dtos/aggregated_notification_dto.dart` (removed 30 lines)

## Files Added
1. `test/refactor_verification/notification_test.dart` (verification test)
2. `test/refactor_verification/notification_confidence.md` (Bayesian analysis)
3. `test/refactor_verification/notification_changelog.md` (this file)

## Preserved (intentionally not removed)
- `NotificationDto`, `NotificationDtoToModelMapper`, `NotificationModel`: While currently unused in active code paths, these represent the individual notification data pipeline that may be needed for future features. Removing them has low benefit and moderate risk.
- All generated files (`*.freezed.dart`, `*.g.dart`) untouched.
- All providers, hooks, use cases, contracts, exceptions unchanged.

## Behavioral Impact
None. Both removed items were dead code with zero call sites.

## Net Effect
- ~40 lines of dead code removed
- 0 public API changes
- 0 logic changes
