<objective>
Final optimization pass: implement efficient push/polling strategy, clean up removed features, add basic test coverage for critical paths, and ensure production readiness.

This is Phase 7 (final) of the refactor. All features are implemented; now optimize and polish.
</objective>

<context>
The refactored app needs:
- Efficient real-time updates (push vs poll decision)
- Removal of all dead code from deprecated features
- Basic test coverage (currently 0%)
- Performance verification
- Production deployment readiness

@CLAUDE.md for patterns
@organisation/REFACTOR_ANALYSIS.md for issues to address

## Already Implemented (Phase 2 - Hybrid Caching Strategy)

The following optimizations were already implemented to avoid WebSocket connection limits:

1. **Avatar Caching**
   - Avatars fetched in parallel (not sequential) via `Future.wait()`
   - Cached on app start, refreshed only on app resume from background
   - No polling for avatars - uses `useAppResumeRefresh` hook
   - Location: `lib/core/features/connection/data/services/connection_service.dart`

2. **App Resume Refresh**
   - New hook: `lib/core/features/connection/domain/hooks/use_app_resume_refresh.dart`
   - Triggers data refresh when app returns from background
   - Used in `home_view.dart` to refresh circle members and notifications

3. **Reduced Polling**
   - Circle members: No polling, refresh on app resume only
   - Notifications: Reduced to 60s polling (was 15s), plus app resume refresh
   - Debug prints removed from home components

## Remaining Work for Phase 7

The hybrid approach requires push notifications for time-critical events:

1. **Lockout Alerts (RESEARCH PHASE - Two Options)**

   **Option A: FCM Push Notifications (Recommended)**
   - When friend starts lockout → Supabase Database Webhook → Edge Function → FCM → All friends notified
   - Pros: No WebSocket connections, reliable delivery, works when app is closed
   - Cons: Requires FCM setup, Edge Function deployment, slight latency (~1-3s)
   - Implementation: Database trigger on `lockout_sessions` INSERT → calls Edge Function → FCM to friend list

   **Option B: Friend-Scoped Supabase Realtime**
   - Subscribe only to lockout changes for your ~150 friends (not global)
   - Query: `.from('lockout_sessions').on('INSERT', callback).eq('user_id', 'in', friendIds)`
   - Pros: Instant updates, simpler setup
   - Cons: Still uses WebSockets (though friend-scoped avoids global limits), requires app to be open

   Decision deferred to Phase 7 implementation based on FCM infrastructure readiness.

2. **Feed "Changed Since?" Optimization (Optional)**
   - Lightweight polling query: "Any new posts since timestamp X?"
   - Server returns yes/no, only fetch if yes
   - Requires: Server-side RPC function
</context>

<research>
Before implementing, examine:
1. Current polling implementation in `use_feed_posts.dart` (15s intervals noted)
2. Supabase Realtime capabilities in the project
3. All files that might have orphaned code from removed features
4. Notification feature status (`lib/core/features/notification/`)
5. Memory management (keepAlive providers audit)
6. Any remaining debug print statements
</research>

<requirements>
1. **Real-Time Strategy**
   Implement efficient update mechanism for:
   - Feed updates when friends post
   - Lockout status changes (friend starts/ends lockout)
   - Friend list changes

   Options to evaluate:
   - **Supabase Realtime**: Subscribe to relevant tables, push updates
   - **Optimized Polling**: Longer intervals with "since timestamp" queries
   - **Hybrid**: Realtime for lockouts (time-sensitive), polling for feed

   Choose based on: complexity, battery impact, server cost, user experience
   Document decision rationale.

2. **Dead Code Removal**
   Remove all code related to deprecated features:
   - time_limit feature (entire directory if unused)
   - link_preview feature (entire directory)
   - Non-lockout post types
   - Call function remnants
   - Unused DTOs, models, services, use cases
   - Unused UI components

   Verify no remaining imports reference removed code.

3. **Notification System Completion**
   Based on analysis: "triggers and push service missing"
   - Implement or complete push notification for lockout events
   - Friend starts lockout → push to all friends
   - Use existing notification infrastructure where possible
   - Firebase Cloud Messaging integration check

4. **Test Coverage**
   Add tests for critical paths (currently 0% coverage):
   - Lockout flow (start, join, complete)
   - Friend connection (add, check limit)
   - Feed query correctness
   - Post creation validation

   Use existing test framework (flutter_test).
   Target: At least unit tests for use cases.

5. **Performance Audit**
   - Audit `keepAlive: true` providers for memory impact
   - Verify feed query uses indexes (check EXPLAIN if possible)
   - Ensure avatar caching is working
   - Check for N+1 query patterns

6. **Production Readiness**
   - Remove all debug print statements
   - Verify flutter analyze passes with no errors
   - Check all environment configs (stage, production)
   - Verify RLS policies are correctly applied
   - Document any manual migration steps needed

**CRITICAL Scalability Fixes (must include):**

7. **Scalability Verification Checklist**
   Before completing Phase 7, verify ALL of the following:
   - [ ] Feed loads in <500ms (50 posts)
   - [ ] Calendar loads in <2s (12 months of data)
   - [ ] Scrolling maintains 60fps (no jank)
   - [ ] Memory stays under 200MB during normal usage
   - [ ] Single polling timer at 5-minute intervals (not multiple timers)
   - [ ] No print statements in production code
   - [ ] Image editing doesn't freeze UI (uses compute())
   - [ ] All caches have size limits or TTL

8. **Performance Regression Prevention**
   Add code review guidelines or lint rules to flag:
   - New `keepAlive: true` providers without size limits
   - New polling intervals under 5 minutes
   - Sequential awaits in loops (for-await patterns)
   - Sort/filter operations in build() or scroll handlers
   - Large allocations in hot paths

   Document these patterns in `organisation/PERFORMANCE_GUIDELINES.md`

9. **Background Preload Orchestration**
   On app start, preload data in this order:
   ```dart
   // 1. Current user profile (BLOCKING - needed for UI)
   await loadCurrentUserProfile();

   // 2. Everything else in parallel (BACKGROUND - non-blocking)
   Future.wait([
     preloadFeedCache(),           // Feed posts
     preloadFriendsCache(),        // Friends list + avatars
     preloadCalendarCurrentMonth(), // Calendar current month
     preloadCalendarPreviousMonth(), // Calendar previous month
   ]);
   ```
   - Use `Future.wait()` for parallel where possible
   - Don't block app launch on secondary data
   - Show loading states in UI while background loads complete

10. **Time Limit Timer Removal**
    - Verify time_limit feature is fully removed (noted as deprecated)
    - Ensure no orphaned timers from this feature
    - Clean up any related local storage keys
</requirements>

<implementation>
For real-time (recommended approach):
```dart
// Supabase Realtime for lockout status
supabase
  .from('lockout_sessions')
  .stream(primaryKey: ['id'])
  .eq('user_id', inList: friendIds)
  .listen((data) => updateLockedOutFriends(data));

// Polling for feed (less critical, 60s interval)
Timer.periodic(Duration(seconds: 60), (_) => refreshFeed());
```

For tests, create in `test/` directory:
```
test/
├── core/
│   ├── features/
│   │   ├── lockout/
│   │   │   └── lockout_use_cases_test.dart
│   │   ├── connection/
│   │   │   └── connection_use_cases_test.dart
│   │   └── post/
│   │       └── post_use_cases_test.dart
```
</implementation>

<output>
Create/modify:
- Real-time subscription setup (location TBD based on research)
- Remove: `lib/core/features/time_limit/` (if fully deprecated)
- Remove: `lib/core/features/link_preview/` (if exists)
- Clean up orphaned imports across codebase
- `test/` directory with critical path tests
- Update `lib/core/features/notification/` for push completeness

Document:
- Real-time vs polling decision with rationale
- All removed files/directories
- Test coverage summary
- Performance findings
- Production deployment checklist
</output>

<constraints>
- Do NOT add new dependencies for testing (use flutter_test)
- Do NOT over-engineer real-time (simple is better)
- Remove features completely - no commented-out code
- Tests should be meaningful, not just for coverage numbers
- Follow existing patterns for any new code
</constraints>

<verification>
Before completing:
1. Real-time/polling implemented and working
2. No references to removed features remain
3. `flutter analyze` passes with no errors
4. Tests pass: `flutter test`
5. No print statements in production code
6. All providers audited for keepAlive
7. Notification push working for lockout events
</verification>

<success_criteria>
- App updates efficiently without excessive polling
- Codebase is clean with no dead code
- Critical paths have test coverage
- Production deployment ready
- Documentation complete for handoff
</success_criteria>

<final_deliverable>
Create `./organisation/REFACTOR_COMPLETE.md` summarizing:
1. All changes made across all phases
2. New database schema overview
3. Removed features
4. Test coverage status
5. Performance characteristics
6. Deployment instructions
7. Known limitations / future work (like iOS Screen Time Phase 2)
</final_deliverable>
