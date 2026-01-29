<objective>
Final scalability verification pass: audit all providers, timers, and async patterns to ensure no scalability issues exist and none were introduced during refactor.

This is Phase 8 (final verification) of the refactor. All features are implemented. Now verify scalability and document findings.
</objective>

<context>
The refactor (Phases 1-7) addressed 15 identified scalability issues and added 3 new caching strategies. This phase ensures:
1. All fixes were correctly implemented
2. No new scalability issues were introduced
3. Performance meets targets at 1M user scale

Key issues that were fixed:
- Dual polling (550K req/sec) → Single 5-min timer
- N+1 calendar queries (337s load) → Batch fetching
- Unbounded feed cache → 100 post limit
- List sort on scroll frame → Memoized sort
- Image memory unbounded → 100 image cache limit
- 7 useEffects in home → 3 consolidated hooks
- Sequential avatar fetching → Batch parallel

New caching added:
- Calendar cache (by month, past months immutable)
- Friends cache (10-min TTL, app-resume refresh)
- Background preload orchestration

@CLAUDE.md for patterns
@organisation/REFACTOR_ANALYSIS.md for original issues
</context>

<research>
Perform comprehensive audits:

1. **Provider Audit**
   - Find all providers with `keepAlive: true`
   - Check each for: size limit, TTL, or natural bounds (like Dunbar's 150)
   - List any that could grow unbounded

2. **Timer/Polling Audit**
   - Find all `Timer.periodic` usages
   - Find all polling intervals in providers/services
   - Verify none are under 5 minutes (except user-facing countdowns)
   - Verify all have cleanup in dispose/onDispose

3. **Async Loop Audit**
   - Search for `for.*await` patterns
   - Search for sequential `.then()` chains in loops
   - Verify all are batched with `Future.wait()` or have documented reason for sequential

4. **Build Method Audit**
   - Check for sort/filter operations inside build()
   - Check for expensive computations in scroll handlers
   - Verify memoization is used where needed
</research>

<requirements>
1. **Audit All Providers**
   Create a table:
   | Provider | keepAlive | Size Limit | TTL | Bounded? | Risk |
   |----------|-----------|------------|-----|----------|------|

   For each `keepAlive: true` provider:
   - Document max size or why unbounded growth is impossible
   - Flag any HIGH risk items for immediate fix

2. **Audit All Timers/Polling**
   Create a table:
   | Location | Interval | Purpose | Cleanup? | Risk |
   |----------|----------|---------|----------|------|

   Flag any intervals under 5 minutes as HIGH risk

3. **Audit All Loops with Await**
   Search patterns:
   ```
   for.*await
   .forEach.*await
   while.*await
   ```

   For each:
   - Is it batched? (using `Future.wait()`)
   - If sequential, is there a good reason?
   - Flag unbatched N>10 loops as HIGH risk

4. **Performance Testing**
   Document actual performance (if testable):
   - Feed with 50 posts: target <500ms
   - Calendar with 12 months: target <3s
   - Scroll performance: target 60fps
   - Memory after 10 min use: target <200MB

5. **Final Cleanup**
   - Remove any remaining print statements
   - Remove dead code from feature removals
   - Verify no orphaned imports
   - Check for TODO comments that should be addressed

6. **Document Known Limitations**
   Things that are acceptable trade-offs:
   - Feed limited to 100 cached posts (older posts re-fetch on scroll)
   - Calendar past months cached forever (user's own data, bounded by history)
   - Avatar URLs refresh on app resume (not real-time)
</requirements>

<implementation>
Use these search patterns:

```bash
# Find keepAlive providers
grep -r "keepAlive: true" lib/

# Find timers
grep -r "Timer.periodic" lib/
grep -r "Duration(seconds:" lib/
grep -r "Duration(minutes:" lib/

# Find for-await patterns
grep -r "for.*await" lib/
grep -r "forEach.*await" lib/

# Find print statements
grep -r "print(" lib/

# Find sort in build
grep -r "\.sort(" lib/presentation/
grep -r "\.where(" lib/presentation/
```

For each finding, trace to understand context before flagging as issue.
</implementation>

<output>
Create: `./organisation/SCALABILITY_AUDIT.md`

Structure:
1. **Executive Summary**
   - Total issues found: X
   - HIGH risk: X (must fix before production)
   - MEDIUM risk: X (fix in next sprint)
   - LOW risk: X (acceptable trade-offs)

2. **Provider Audit Results**
   - Table of all keepAlive providers
   - Findings and fixes

3. **Timer/Polling Audit Results**
   - Table of all intervals
   - Findings and fixes

4. **Async Pattern Audit Results**
   - List of sequential awaits found
   - Batching status

5. **Performance Measurements**
   - Actual timings if testable
   - Memory usage observations

6. **Final Cleanup Log**
   - Print statements removed
   - Dead code removed
   - Files cleaned

7. **Known Limitations & Trade-offs**
   - Documented acceptable limitations

8. **Sign-off Checklist**
   - [ ] All HIGH risk issues resolved
   - [ ] Performance targets met
   - [ ] No print statements
   - [ ] flutter analyze clean
   - [ ] Ready for production
</output>

<constraints>
- Do NOT make changes in this phase unless they are HIGH risk fixes
- Document everything, even if it looks fine
- Be thorough - this is the final check before production
- If you find issues, categorize by risk level and document fix strategy
</constraints>

<verification>
Before completing:
1. All providers audited and documented
2. All timers audited and documented
3. All async loops audited and documented
4. Performance measurements recorded (or noted as untestable)
5. Cleanup completed
6. SCALABILITY_AUDIT.md created with full findings
</verification>

<success_criteria>
- Comprehensive audit document exists
- No HIGH risk issues remain unfixed
- All scalability fixes from Phases 1-7 verified as implemented
- Confidence that app will scale to 1M users
- Clear documentation of any remaining limitations
</success_criteria>

<issue_coverage_verification>
Verify each of these issues was addressed in the appropriate phase:

| Issue | Fixed In | Verification |
|-------|----------|--------------|
| Dual polling (550K req/sec) | 004 | Single timer, 5-min interval |
| N+1 calendar queries (337s load) | 005 | Batch fetching with Future.wait |
| Unbounded feed cache | 004 | maxPosts: 100 |
| List sort on scroll frame | 004 | useMemoized for sorted list |
| Time limit timer (removed) | 007 | Feature fully removed |
| hidePost race condition | 004 | Atomic SQL update |
| Feed N+2 subqueries | 001 | Denormalized counts |
| Signed URL concurrency | 004 | concurrency: 15 |
| Image memory unbounded | 006 | imageCache.maximumSize = 100 |
| 7 useEffects in home | 006 | Consolidated to 3 hooks |
| Debug prints | 006, 007 | All removed |
| Notification index | 001 | Compound index added |
| Friendship OR clause | 001 | Normalized index |
| Image flip main thread | 006 | compute() isolate |
| Calendar grid recalc | 005 | useMemoized |
| Calendar caching | 005 | CalendarCacheProvider |
| Friends caching | 002 | FriendsCacheProvider |
| Background preload | 007 | Orchestrated startup |
</issue_coverage_verification>
