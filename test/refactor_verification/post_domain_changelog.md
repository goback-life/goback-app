## Post Domain Layer - Refactoring Changelog

### Files DELETED (dead code removal)

1. **lib/core/features/post/domain/hooks/use_feed_posts/feed_posts_actions.dart**
   - What: Entire file deleted
   - Why: `FeedPostsActions` class was never imported or referenced outside its own file.
     Legacy helper from before `useFeedPosts` was refactored to use `FeedPostsCache` directly.
   - Risk: NONE (confirmed zero external references via grep)

2. **lib/core/features/post/domain/hooks/use_feed_posts/feed_posts_polling.dart**
   - What: Entire file deleted
   - Why: `FeedPostsPolling` class was never imported or referenced outside its own file.
     Legacy helper from before `useFeedPosts` was refactored to use `FeedPostsCache` directly.
   - Risk: NONE (confirmed zero external references via grep)

### Files MODIFIED

3. **lib/core/features/post/domain/providers/feed_posts_cache_provider.dart**
   - What changed:
     - REDUCED from 563 lines to 488 lines (under 500-line lint limit)
     - Removed dead `updateCache()` method (no callers after dead files deleted)
     - Removed dead `isCacheValid` getter (no external callers)
     - Removed dead `lastEnrichedAt` getter (no external callers)
     - Removed dead `_lastEnrichedAt` field (orphaned internal state)
     - Extracted `_appendAndTruncate()` private helper to eliminate duplicated
       dedup+append+truncate logic from `_loadNextBatch` and `loadMorePostsNow`
     - Simplified `_checkForNewPostsInBackground` by merging two equivalent
       branches (newestCached == null vs != null) into a single filter
     - Cleaned up blank lines from field removal
   - Why: File was over 500-line lint limit; contained dead code and duplicated logic
   - Risk: LOW (all removals verified as dead; logic extraction preserves behavior)

4. **lib/core/features/post/domain/providers/post_creation_notifier_provider.dart**
   - What changed: Removed dead `updatePostType()` method
   - Why: Identical to `updateContentType()` which is the one actually called.
     `updatePostType` had zero callers anywhere in the codebase.
   - Risk: NONE (confirmed zero references via grep)

5. **lib/core/features/post/domain/hooks/use_join_lockout_post.dart**
   - What changed: Removed trailing blank line
   - Risk: NONE (cosmetic)

6. **lib/core/features/post/domain/constants/text_post_constants.dart**
   - What changed: Removed trailing blank line
   - Risk: NONE (cosmetic)

7. **lib/core/features/post/domain/models/link_preview_model.dart**
   - What changed: Removed trailing blank line
   - Risk: NONE (cosmetic)

8. **lib/core/features/post/domain/utilities/text_post_parser.dart**
   - What changed: Removed trailing blank line
   - Risk: NONE (cosmetic)

9. **lib/core/features/post/domain/utilities/url_shortener.dart**
   - What changed: Removed trailing blank line
   - Risk: NONE (cosmetic)

### Files CREATED

10. **test/refactor_verification/post_domain_test.dart**
    - What: Verification test documenting all public APIs and contracts
    - Why: Required by refactoring methodology Step 2

11. **test/refactor_verification/post_domain_confidence.md**
    - What: Bayesian confidence analysis
    - Why: Required by refactoring methodology Step 4

12. **test/refactor_verification/post_domain_changelog.md**
    - What: This file
    - Why: Required by refactoring methodology Step 5

### Public API Changes: NONE
All public provider names, hook return types, model fields, and method
signatures remain unchanged. The only removals were methods with zero callers.
