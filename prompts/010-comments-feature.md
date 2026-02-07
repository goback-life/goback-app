<objective>
Implement post comments feature with denormalized counts and optimized queries.

This is Phase 10 of the refactor. Builds on feed simplification (Phase 4).
</objective>

<context>
Comments infrastructure exists but is dormant:
- Database: `post_comments` table with soft delete
- Flutter: `lib/core/features/comment/` with services, models, providers
- RPC: `get_post_comments()` function exists
- Missing: UI integration, count display, denormalized counts

Current: `get_user_feed()` has N+1 subquery for comment_count.
</context>

<requirements>
1. **Denormalize comment_count**
   - Add `comment_count INT DEFAULT 0` to posts table
   - Create trigger for INSERT/UPDATE(deleted_at)/DELETE on post_comments
   - Backfill existing counts
   - Update get_user_feed() to use denormalized column

2. **Add counts to FeedPostModel**
   - Add `reactionCount` and `commentCount` fields
   - Update FeedPostDto to parse from RPC response
   - Update mapper

3. **UI Integration**
   - Display counts on post cards
   - Comment button/indicator
   - Navigate to comments view on tap

4. **Comments View**
   - List comments for a post
   - Add new comment (text input)
   - Delete own comments (soft delete)
   - Pull to refresh

5. **Notifications**
   - Notification when someone comments on your post
   - Already has trigger: `trg_notification_on_comment`
</requirements>

<constraints>
- Reuse existing `lib/core/features/comment/` infrastructure
- Follow existing UI patterns from reactions
- Keep comment length limit (500 chars per DB constraint)
- Soft delete only (preserve audit trail)
</constraints>

<verification>
1. Comment on a post -> count increments
2. Delete comment -> count decrements
3. Feed loads with counts (no N+1)
4. Notification received by post author
</verification>
