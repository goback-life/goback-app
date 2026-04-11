# Changelog: Calendar + Comment + Media Refactoring

## Files Modified

### 1. `lib/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart`
- **Before**: 259 lines with 8+ repeated date normalization patterns and duplicated sort/user-check logic
- **After**: 157 lines (39% reduction)
- **Changes**:
  - Extracted `_dateOnly()` file-level helper to replace repeated `DateTime(dt.year, dt.month, dt.day)` pattern
  - Extracted `_ensureUser()` to consolidate identical user-switch-and-clear logic from `updateCache` and `mergePosts`
  - Extracted `_sortedBy({String? authorId})` to consolidate identical sort logic from 6 public methods
  - Extracted `_indexOfDate()` to consolidate index-finding logic shared by `isNearEnd` and `isNearBeginning`
  - All public method signatures UNCHANGED

### 2. `lib/core/features/calendar/data/mappers/calendar_post_dto_to_model_mapper.dart`
- **Before**: Standalone class with hand-written `mapDtoList`
- **After**: Extends `DtoToModelMapperContract<CalendarPostDto, CalendarPostModel>`, inherits `mapDtoList`
- **Changes**:
  - Added `extends DtoToModelMapperContract<CalendarPostDto, CalendarPostModel>`
  - Added `@override` annotation to `mapDto`
  - Removed redundant `mapDtoList` (inherited from base contract, identical implementation)
  - Consistent with `CommentDtoToModelMapper` which already extends the base contract
  - Inlined `excludedUserIds` assignment (removed unnecessary local variable)

### 3. `lib/core/features/media/domain/enums/image_source.dart`
- **DELETED** - Dead code with zero imports across the entire codebase
- The `ImageSource` enum (`camera, gallery`) duplicated `PickImageType` and was never imported
- Code uses `image_picker`'s `ImageSource` and the project's `PickImageType` instead

## Files Created
- `test/refactor_verification/cal_comment_media_test.dart` - Verification test covering public API surface
- `test/refactor_verification/cal_comment_media_confidence.md` - Bayesian confidence analysis
- `test/refactor_verification/cal_comment_media_changelog.md` - This file

## Summary
- **3 source files** touched (2 modified, 1 deleted)
- **3 test/doc files** created
- **No public API changes**
- **No logic changes**
- **No new dependencies**
- **102 lines removed** from production code
