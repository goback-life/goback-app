<objective>
Update the profile feature to display weekly lockout stats, refactor the calendar to show lockout history (not saved posts), and remove the call function.

This is Phase 5 of the refactor. Builds on previous phases for data availability.
</objective>

<context>
Profile page changes:
- Remove: call function (not needed)
- Add: weekly lockout hours stat display
- Change: calendar shows lockout history, not saved posts
- Keep: avatar, username, bio, phone number, friends list

Calendar behavior:
- Clicking a day shows lockout posts from that day
- Shows the user's own posts after their lockouts
- Historical data beyond 24h feed window

Current: `lib/core/features/profile/` and profile UI pages
@CLAUDE.md for patterns
</context>

<research>
Before implementing, examine:
1. Current profile feature in `lib/core/features/profile/`
2. Profile page UI in `lib/presentation/pages/` (find profile page)
3. Current calendar implementation (if exists)
4. How "saved posts" currently works
5. Weekly stats calculation from Phase 3 lockout work
6. Call function implementation (to remove)
</research>

<requirements>
1. **Weekly Lockout Stats**
   - Display on profile: "X hours locked out this week"
   - Pull from lockout feature's GetWeeklyStats use case (Phase 3)
   - Update in real-time or on profile load
   - Week resets Sunday midnight UTC (or make configurable)

2. **Calendar View Refactor**
   - Calendar shows days where user had completed lockouts
   - Indicator dot/highlight on days with lockout posts
   - Tapping a day shows that day's lockout post(s)
   - Query: user's own posts by date (not limited to 24h)

3. **Remove Call Function**
   - Remove call button from profile UI
   - Remove any call-related services/use cases
   - Clean up unused imports

4. **Profile Data Optimization**
   - Ensure profile queries are efficient
   - Avatar URL caching (coordinate with connections phase)
   - Minimize re-fetches on navigation

5. **Friends List on Profile**
   - Already optimized in Phase 2
   - Ensure profile page uses updated connection providers

**CRITICAL Scalability Fixes (must include):**

6. **Calendar Caching with Background Preload (HIGH PRIORITY)**
   - Current issue: N+1 queries in calendar service = 337s load time
   - Add `CalendarCacheProvider` with `keepAlive: true`
   - Structure:
     ```dart
     CalendarCacheState {
       Map<String, List<CalendarPost>> postsByMonth;  // "2026-01" -> posts
       Set<String> loadedMonths;
       DateTime lastFetchedAt;
     }
     ```
   - On app start: preload current month and previous month (background)
   - On profile open: instant display from cache
   - Past months are immutable - cache forever (no TTL needed)
   - Current month: 5-minute TTL (new posts may appear)

7. **Batch Avatar/Media Fetching in Calendar Service (HIGH PRIORITY)**
   - Current issue: Sequential for-loop for signed URLs
   - Replace with batched `Future.wait()`:
     ```dart
     // BAD - sequential (337 seconds for 12 months)
     for (final post in posts) {
       post.mediaUrl = await getSignedUrl(post.mediaPath);
       post.authorAvatarUrl = await getSignedUrl(post.authorAvatarPath);
     }

     // GOOD - batched parallel (~2 seconds)
     final batches = posts.chunked(15);
     for (final batch in batches) {
       await Future.wait([
         ...batch.map((p) => enrichMediaUrl(p)),
         ...batch.map((p) => enrichAuthorAvatar(p)),
       ]);
     }
     ```
   - Max 15 concurrent signed URL requests

8. **Memoize Calendar Grid Calculation**
   - Use `useMemoized()` for `_calculateMonthWeeks()` in calendar widget
   - Only recalculate when month changes
   - Pattern:
     ```dart
     final monthWeeks = useMemoized(
       () => _calculateMonthWeeks(selectedMonth),
       [selectedMonth],
     );
     ```
</requirements>

<implementation>
Calendar query:
```sql
-- Get user's lockout posts grouped by date
SELECT DATE(created_at) as post_date, COUNT(*) as post_count
FROM posts
WHERE user_id = $user_id
GROUP BY DATE(created_at)
ORDER BY post_date DESC;

-- Get posts for specific date
SELECT * FROM posts
WHERE user_id = $user_id
AND DATE(created_at) = $selected_date
ORDER BY created_at DESC;
```

For weekly stats display:
- Use provider from lockout feature
- Format as "Xh Ym" or just hours if cleaner
- Consider: streak counter, comparison to last week (future enhancement - note but don't implement)
</implementation>

<output>
Modify in `lib/core/features/profile/`:
- `data/services/` - Add calendar query methods
- `domain/use_cases/` - Add GetCalendarDays, GetPostsForDate use cases
- `domain/providers/` - Add calendar data provider
- Remove: any call-related code

Document for UI phase:
- Profile page changes needed
- Calendar component requirements
- Weekly stats display location
- Call button removal

Note: UI changes will be implemented in Phase 6
</output>

<constraints>
- Do NOT implement UI changes in this phase
- Do NOT add saved posts feature (it's being replaced)
- Keep profile CRUD working (update bio, avatar, etc.)
- Follow existing patterns
</constraints>

<verification>
Before completing:
1. Weekly lockout stats available via provider
2. Calendar days query returns correct dates
3. Posts for specific date query works
4. Call-related code removed from feature layer
5. Profile feature still works for basic operations
</verification>

<success_criteria>
- Weekly lockout hours stat accessible in profile
- Calendar can query lockout history by date
- Call function code removed
- Profile feature clean and optimized
</success_criteria>
