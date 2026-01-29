<objective>
Refactor the lockout feature to use the new `lockout_sessions` table, add join functionality improvements, and implement weekly lockout stats tracking.

This is Phase 3 of the refactor. Builds on the new schema (Phase 1) and updated connections system (Phase 2).
</objective>

<context>
The lockout feature is the core of Goback:
- User presses button → chooses duration → optionally adds action text → locked out
- Location logged during lockout
- Friends notified and can join the lockout
- On return: user can post what they did (links to post feature)
- Profile shows weekly lockout hours stat

Current implementation rated 9/10 in analysis - refactor, don't rebuild.
Current location: `lib/core/features/lockout/`
New schema: `./organisation/DATABASE_SCHEMA_V2.md`

@CLAUDE.md for coding patterns
@organisation/REFACTOR_ANALYSIS.md for current implementation assessment
</context>

<research>
Before implementing, examine:
1. Current lockout feature in `lib/core/features/lockout/`
2. Existing use cases: Check, GetRemainingTime, Set, Join, Clear
3. `ManualLockoutStorable` for local persistence
4. `ManualLockoutNotifier` Riverpod provider
5. How lockout posts are currently created (`is_lockout_post` flag)
6. The new `lockout_sessions` table design from Phase 1
</research>

<requirements>
1. **Lockout Sessions Table Integration**
   - Create lockout session record when user initiates lockout
   - Store: user_id, started_at, ends_at, action_text, location
   - Track participants array when friends join
   - Link to post_id when lockout completes and user posts

2. **"Friends Locked Out" View**
   - Query friends currently in active lockouts
   - Return: friend profile, lockout action, location, time remaining
   - This powers the lockout screen scroll view
   - Must be efficient for users with 150 friends

3. **Join Lockout Enhancement**
   - When joining, add user to participants array
   - Joiner's lockout ends when initiator's ends
   - Both get tagged in resulting post

4. **Weekly Stats Tracking**
   - Calculate total lockout minutes for current week
   - Either: computed on query, or stored/updated incrementally
   - Displayed on profile page
   - Reset weekly (define week boundary: Sunday midnight UTC?)

5. **Notification Triggers**
   - When user starts lockout → notify all friends
   - Include: duration, action, location in notification
   - Friends see option to join

6. **Local State**
   - Keep `ManualLockoutStorable` for offline/fast access
   - Sync with server `lockout_sessions` table
   - Handle edge cases: app killed during lockout, timezone changes

**CRITICAL Scalability Fixes (must include):**

7. **Friends Locked Out Caching**
   - Cache "friends currently locked out" query result
   - Refresh every 2 minutes (lockouts change slowly, median duration ~30min)
   - Invalidate cache on push notification of new lockout
   - Structure:
     ```dart
     FriendsLockedOutCacheState {
       List<ActiveLockoutModel> activeLockouts;
       DateTime lastFetchedAt;
     }
     ```

8. **Efficient Lockout Status Query**
   - Ensure index on `lockout_sessions(ends_at)` for active lockout lookup
   - Consider partial index: `CREATE INDEX idx_active_lockouts ON lockout_sessions(user_id, ends_at) WHERE ends_at > NOW()`
   - Query pattern: `WHERE ends_at > NOW() AND user_id = ANY($friendIds)`
</requirements>

<implementation>
Preserve what works (rated 9/10):
- Use case structure (Check, GetRemainingTime, Set, Join, Clear)
- Result<T> pattern
- `ManualLockoutNotifier` approach

Add/modify:
- New `LockoutSessionDto` and `LockoutSessionModel` for server data
- Service methods for lockout_sessions CRUD
- Query for "friends currently locked out"
- Weekly stats calculation
- Update Set use case to create server session
- Update Join use case to modify participants array

For notifications, check if notification feature infrastructure exists in `lib/core/features/notification/` - use it or note what's missing.
</implementation>

<output>
Modify files in `lib/core/features/lockout/`:
- `data/dtos/` - Add LockoutSessionDto
- `data/services/` - Add session CRUD, friends-locked-out query
- `data/mappers/` - Add session mapper
- `domain/models/` - Add LockoutSessionModel
- `domain/use_cases/` - Update existing, add GetFriendsLockedOut, GetWeeklyStats
- `domain/providers/` - Update notifier for new functionality

If notification infrastructure is incomplete, document what's needed but do not implement full notification system in this phase.

After changes, list:
- Files modified
- New use cases added
- How weekly stats are calculated
- Notification integration status
</output>

<constraints>
- Do NOT rebuild the lockout feature from scratch
- Do NOT modify UI in this phase
- Keep local storage (`ManualLockoutStorable`) working
- Maintain offline-first behavior where possible
- Follow existing patterns exactly
</constraints>

<verification>
Before completing:
1. Lockout creates server-side session record
2. Join adds user to participants array
3. "Friends locked out" query returns correct data
4. Weekly stats calculation works
5. Local state stays in sync with server
6. Existing lockout flow still works end-to-end
</verification>

<success_criteria>
- Lockout sessions stored in new table structure
- Friends can see who's locked out efficiently
- Join lockout properly tracks participants
- Weekly lockout minutes stat available for profile
- Backward compatible with existing lockout data
</success_criteria>
