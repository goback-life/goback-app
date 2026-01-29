<objective>
Update all UI components to reflect the refactored backend: simplified feed, lockout-only posts, calendar lockout history, weekly stats, and removed features.

This is Phase 6 of the refactor. All backend changes from Phases 1-5 are complete. Now update the presentation layer.
</objective>

<context>
UI changes needed:
- Feed: shows only lockout posts, 24h window, participant tags
- Lockout screen: big button, duration picker, action input, friends-locked-out scroll
- Post creation: only accessible after lockout, photo/video picker, participant display
- Profile: weekly stats display, calendar shows lockout history, no call button
- Friends list: optimized avatar loading

Current UI: `lib/presentation/pages/` and `lib/presentation/components/`
@CLAUDE.md for patterns (especially UI rules: no business logic in widgets)
</context>

<research>
Before implementing, examine:
1. All page structures in `lib/presentation/pages/`
2. Home/feed page implementation
3. Lockout page implementation
4. Profile page implementation
5. Post creation flow
6. Shared components in `lib/presentation/components/`
7. Large files noted in analysis: `full_screen_image.dart` (934 lines), `home_feed_post_card.dart` (477 lines)
8. Changes documented in previous phase summaries
</research>

<requirements>
1. **Feed Page Updates**
   - Use new simplified feed provider
   - Display lockout posts only
   - Show participant tags on post cards
   - Remove any non-lockout post type handling
   - Implement efficient infinite scroll with new cursor pagination

2. **Lockout Page Updates**
   - Big prominent "Lock Out" button
   - Duration picker (preset options or custom)
   - Optional action text input
   - Location permission/display
   - "Friends Currently Locked Out" scrollable list
     - Shows: avatar, name, action, location, time remaining
     - "Join" button on each

3. **Post Creation Flow**
   - Only accessible from post-lockout return flow
   - Photo/video picker (single media)
   - **Video duration limit: 60 seconds max**
     - Check duration immediately after video selection
     - Show user-friendly error if too long: "Videos must be 60 seconds or less"
     - Do not allow upload to proceed for longer videos
   - Timestamp validation (must be from lockout day)
   - Display participants (auto-tagged from lockout session)
   - Simple "Share" action

4. **Profile Page Updates**
   - Add weekly lockout hours stat (prominent placement)
   - Calendar shows days with lockout posts (dot indicators)
   - Tap day → show that day's lockout post(s)
   - Remove call button completely
   - Friends list uses optimized avatar loading

5. **Notification Display**
   - When friend starts lockout: show notification with join option
   - Deep link to lockout page with join action

6. **Cleanup Large Files**
   - Split `full_screen_image.dart` (934 lines) into smaller components
   - Refactor `home_feed_post_card.dart` (477 lines) if beneficial
   - Target: all files under 500 lines

**CRITICAL Scalability Fixes (must include):**

7. **Consolidate home_view useEffects (HIGH PRIORITY)**
   - Current issue: 7 separate useEffect hooks cause complexity and potential race conditions
   - Merge into 3 focused hooks:
     ```dart
     // 1. Data loading (initial load, preload, app resume)
     useHomeDataLoader(ref, {
       onInitialLoad: () => /* fetch feed, friends, notifications */,
       onAppResume: () => /* refresh stale data */,
     });

     // 2. Scroll tracking (position, date badge)
     useHomeScrollTracking(scrollController, {
       onDateChange: (date) => updateDateBadge(date),
     });

     // 3. Post actions (creation, update events)
     useHomePostActions(ref, {
       onPostCreated: (post) => addToFeed(post),
       onPostUpdated: (post) => updateInFeed(post),
     });
     ```

8. **Set Global Image Cache Limit**
   - In app initialization (main.dart or similar):
     ```dart
     PaintingBinding.instance.imageCache.maximumSize = 100;
     PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
     ```
   - Prevents OOM on scroll-heavy usage

9. **Move Image Flip to compute() (HIGH PRIORITY)**
   - Current issue: PNG encoding in `full_screen_image.dart` freezes UI for 500ms-2s
   - Use `compute()` for off-main-thread processing:
     ```dart
     // BAD - blocks main thread
     final flipped = await image.flipHorizontal();
     final bytes = await flipped.toPng();

     // GOOD - runs in isolate
     final bytes = await compute(_flipAndEncode, imageData);

     static Uint8List _flipAndEncode(ImageData data) {
       // Flip and encode in isolate
     }
     ```

10. **Remove ALL Debug Print Statements**
    - Locations to check:
      - `home_view.dart`
      - `home_feed_posts_list.dart`
      - `post_query_service.dart`
      - `connection_service.dart`
    - Replace with logger if debugging info is truly needed:
      ```dart
      // BAD
      print('Feed loaded: ${posts.length} posts');

      // GOOD (if needed at all)
      logger.d('Feed loaded: ${posts.length} posts');
      ```
</requirements>

<implementation>
UI patterns to follow:
- Widgets: UI only, no Supabase calls, pure build()
- Use hooks for local UI state
- Use Riverpod providers for data (read from refactored domain layer)
- Match existing theming and spacing
- Extract widgets only when readability improves materially

For large file splitting:
- Identify logical component boundaries
- Extract to separate files in same page's `components/` folder
- Keep the main page file as orchestrator

For the "Friends Locked Out" scroll:
- Consider horizontal scroll or vertical list based on existing UX patterns
- Show loading states
- Handle empty state ("No friends locked out right now")
</implementation>

<output>
Modify in `lib/presentation/`:
- `pages/home/` - Feed updates
- `pages/lockout/` - Lockout page redesign (or create if doesn't exist)
- `pages/profile/` - Stats, calendar, remove call
- `pages/post/` or post creation flow location
- `components/` - Shared component updates

Split large files:
- Document what was extracted from `full_screen_image.dart`
- Document what was extracted from `home_feed_post_card.dart`

After changes, list:
- All files modified
- Components extracted/created
- Removed UI code for deprecated features
- Any new routes needed
</output>

<constraints>
- Do NOT add business logic to widgets
- Do NOT make Supabase calls from UI layer
- Match existing theme/styling (no redesigns unless necessary)
- Keep route structure stable where possible
- All files must be under 500 lines
- Remove debug print statements (7 found in home_view.dart)
</constraints>

<verification>
Before completing:
1. Feed shows lockout posts only with participant tags
2. Lockout page has all required elements
3. Post creation only accessible post-lockout
4. Profile shows weekly stats and calendar works
5. Call button removed
6. No files over 500 lines
7. No print statements (use logger instead)
8. No business logic in widgets
</verification>

<success_criteria>
- All UI reflects new simplified feature set
- User flows work end-to-end
- Code is clean and under line limits
- Consistent with existing design patterns
</success_criteria>
