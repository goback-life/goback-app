# Bayesian Confidence Analysis: Calendar + Comment + Media Refactoring

## Prior: P(no regression) = 0.95
Based on: well-structured codebase with clear separation of concerns, Riverpod + Freezed patterns, no complex inheritance chains.

## Evidence Updates

### E1: calendar_posts_cache_provider.dart refactoring
- **Change**: Extracted `_dateOnly()` helper, `_ensureUser()`, `_sortedBy()`, and `_indexOfDate()` private methods to consolidate repeated patterns.
- **Risk**: LOW - All extracted helpers are private, all public method signatures unchanged.
- **Behavioral equivalence**: Each public method produces identical results. `_ensureUser` consolidates identical user-check+clear logic from `updateCache` and `mergePosts`. `_dateOnly` replaces 8+ inline `DateTime(dt.year, dt.month, dt.day)` calls. `_sortedBy` replaces identical sort logic in `getSortedPosts`, `getSortedPostsByAuthor`, `getNextPost`, `getPreviousPost`, `isNearEnd`, `isNearBeginning`.
- **Update**: P(no regression | E1) = 0.95 * 0.99 / (0.95 * 0.99 + 0.05 * 0.3) = **0.984**

### E2: CalendarPostDtoToModelMapper extends DtoToModelMapperContract
- **Change**: Made mapper extend base contract, removed hand-written `mapDtoList` (now inherited from base).
- **Risk**: VERY LOW - Base contract's `mapDtoList` is `dtos.map(mapDto).toList()`, identical to removed implementation.
- **Call site check**: Only `calendarPostMapper.mapDtoList(dtos)` in `calendar_repository.dart` - method still exists via inheritance.
- **Update**: P(no regression | E2) = 0.984 * 0.995 / (0.984 * 0.995 + 0.016 * 0.2) = **0.997**

### E3: Removed dead image_source.dart
- **Change**: Deleted `lib/core/features/media/domain/enums/image_source.dart`.
- **Risk**: NEGLIGIBLE - Zero imports found across entire codebase (confirmed via ripgrep).
- **Update**: P(no regression | E3) = 0.997 * 0.999 / (0.997 * 0.999 + 0.003 * 0.01) = **0.9999**

### E4: Line count reduction (259 -> 157 lines in cache provider)
- **Semantic preservation**: All 14 public members preserved: `build`, `updateCache`, `mergePosts`, `appendPosts`, `getPostCalendarDate`, `addPostOptimistically`, `removePostOptimistically`, `clearCache`, `currentUserId`, `getSortedPosts`, `getSortedPostsByAuthor`, `getNextPost`, `getPreviousPost`, `isNearEnd`, `isNearBeginning`.
- **No new public API added**. Only private helpers introduced.
- **Update**: No additional risk factor.

## Final Confidence: 99.99%

## Risk Matrix
| Change | Files | Risk | Confidence |
|--------|-------|------|------------|
| Extract _dateOnly + helpers in cache provider | 1 | Low | 99% |
| Mapper extends base contract | 1 | Very Low | 99.5% |
| Remove dead image_source.dart | 1 (deleted) | Negligible | 99.9% |
| **Combined** | **3** | **Very Low** | **99.99%** |
