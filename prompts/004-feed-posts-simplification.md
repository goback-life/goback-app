<objective>
Simplify the feed and posts system to only support lockout-completion posts, optimize the feed query for scalability, and implement 24-hour auto-expiration.

This is Phase 4 of the refactor. Builds on schema (Phase 1), connections (Phase 2), and lockout (Phase 3).
</objective>

<context>
The new post flow is restricted and predictable:
1. User completes a lockout
2. User optionally creates ONE post for that lockout
3. Post includes: photo/video + timestamp, tagged participants (initiator + joiners)
4. Post appears in friends' feeds for 24 hours
5. After 24h, post no longer shows in feed (but stays in user's calendar history)

This simplification (vs free posting) enables major optimization opportunities.

Current: `lib/core/features/post/` and `lib/presentation/pages/home/`
New schema: `./organisation/DATABASE_SCHEMA_V2.md`

@CLAUDE.md for patterns
@organisation/REFACTOR_ANALYSIS.md - notes feed rated 6/10, needs work
</context>

<research>
Before implementing, examine:
1. Current post feature in `lib/core/features/post/`
2. Current feed implementation in `lib/presentation/pages/home/` (especially `use_feed_posts.dart`)
3. Current `get_user_feed()` RPC function
4. `post_service.dart` (536 lines - may need splitting)
5. How `is_lockout_post` flag is currently used
6. Media upload flow in post creation
7. The new posts table design from Phase 1
</research>

<requirements>
1. **Simplify Post Creation**
   - Posts ONLY created after lockout completion
   - Link post to lockout_session_id
   - Tag participants from lockout session
   - Support: photo OR video (not both), taken that day or from gallery with timestamp validation
   - Remove: all non-lockout post creation paths

2. **Optimize Feed Query**
   - Feed = friends' posts from last 24 hours, chronological (newest first)
   - With lockout-only posts, query is simpler:
     - No parent_id handling (no replies)
     - No post_exclusions (simpler privacy - friends only)
     - Direct JOIN on friendships + posts + profiles
   - Create optimized RPC or direct query
   - Consider: cursor-based pagination for infinite scroll

3. **24-Hour Feed Expiration**
   - Posts older than 24h excluded from feed query (WHERE clause)
   - Posts NOT deleted - still accessible via calendar
   - Option: Supabase scheduled function to clean up or just filter at query time

4. **Participant Tagging**
   - Posts store array of participant user_ids (from lockout session)
   - Display tagged users on post card
   - Clicking tag navigates to that user's profile

5. **Media Handling**
   - Keep existing compression (flutter_image_compress)
   - Single media per post (simplification)
   - Store media_type (photo/video) and storage_path
   - **Video duration limit: 60 seconds max**
     - Validate on client before upload (reject longer videos)
     - Store `duration_seconds` in post_media table
     - DB constraint enforces limit as backup

6. **Remove Unused Post Types**
   - Remove code paths for non-lockout posts
   - Remove link_preview related code
   - Remove reply/thread functionality if exists
   - Clean up unused DTOs/models

**CRITICAL Scalability Fixes (must include):**

7. **Merge Dual Polling Into Single Timer (HIGH PRIORITY)**
   - Current issue: Two timers polling at 15s and 60s intervals = 550K req/sec at 1M users
   - Combine `pollingController` and `updatePollingController` into single timer
   - Single 5-minute interval (300 seconds, not 60 seconds)
   - Check for both new posts AND updates in one request
   - Pattern:
     ```dart
     // Single timer, 5-minute interval
     Timer.periodic(Duration(minutes: 5), (_) {
       fetchNewAndUpdatedPosts(since: lastFetchTimestamp);
     });
     ```

8. **Feed Cache Size Limit (HIGH PRIORITY)**
   - Add `maxPosts: 100` to `FeedPostsCacheProvider`
   - Evict oldest when limit reached
   - Keep `removeExpiredPosts()` for 24h cleanup
   - Rationale: Prevents unbounded memory growth

9. **Memoize Sorted Posts (HIGH PRIORITY)**
   - Current issue: `home_feed_posts_list.dart` sorts on every scroll frame
   - Sort ONCE when posts change, store sorted list in state
   - Use `useMemoized()` or `useRef()` to cache sorted list
   - Pattern:
     ```dart
     final sortedPosts = useMemoized(
       () => [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
       [posts],
     );
     ```

10. **Increase Signed URL Concurrency**
    - Change `concurrency: 5` to `concurrency: 15` in `post_query_service.dart`
    - Reduces feed enrichment from 1.35s to ~300ms
    - Stays within safe limits for Supabase

11. **Atomic hidePost Operation**
    - Current issue: Read-modify-write race condition
    - Replace with atomic SQL:
      ```sql
      UPDATE posts
      SET excluded_user_ids = array_append(excluded_user_ids, $userId)
      WHERE id = $postId
      AND NOT ($userId = ANY(excluded_user_ids))
      ```
</requirements>

<implementation>
Feed optimization strategy:
```sql
-- Simplified feed query concept
SELECT p.*, pr.username, pr.avatar_url
FROM posts p
JOIN friendships f ON f.friend_id = p.user_id AND f.user_id = $current_user
JOIN profiles pr ON pr.id = p.user_id
WHERE p.created_at > NOW() - INTERVAL '24 hours'
ORDER BY p.created_at DESC
LIMIT 20 OFFSET $cursor;
```

Replace complex `get_user_feed()` RPC with simpler version.

For polling vs realtime:
- Consider Supabase Realtime subscription for new posts (push model)
- Or: efficient polling with "posts since timestamp" query
- Document trade-offs and implement one approach
</implementation>

<output>
Modify in `lib/core/features/post/`:
- `data/dtos/` - Simplify PostDto, remove unused fields
- `data/services/post_service.dart` - Simplify, split if over 500 lines
- `domain/models/` - Simplify PostModel
- `domain/use_cases/` - Remove non-lockout post creation use cases

Modify/create Supabase function:
- `./db/migrations/002_simplified_feed_rpc.sql` - New feed query

Document in summary:
- Removed code paths
- New feed query performance characteristics
- Polling vs realtime decision
- Breaking changes for UI layer
</output>

<constraints>
- Do NOT modify UI components in this phase (list what needs updating)
- Keep media upload flow working
- Ensure calendar history queries still work (posts beyond 24h)
- Follow existing service patterns
- `post_service.dart` must be under 500 lines after refactor
</constraints>

<verification>
Before completing:
1. Posts can only be created linked to a lockout session
2. Feed query returns only friends' posts from last 24h
3. Feed query is efficient (check query plan if possible)
4. Old posts still accessible for calendar view
5. Media upload still works
6. No orphaned code for removed post types
</verification>

<success_criteria>
- Post creation restricted to post-lockout flow
- Feed query optimized and simplified
- 24h expiration working
- Participant tagging functional
- Code is cleaner and more maintainable
</success_criteria>
