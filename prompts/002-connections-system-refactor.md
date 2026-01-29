<objective>
Refactor the connections/friends system to use the new database schema (from Phase 1) with optimized queries and caching for scalability.

This is Phase 2 of the refactor. The new schema from `./organisation/DATABASE_SCHEMA_V2.md` must be implemented in the Flutter codebase.
</objective>

<context>
The connections system handles:
- Adding friends via phone number lookup
- Invite codes with 72h expiry
- Bidirectional friendship (mutual consent)
- 150 friend limit per user
- Friends list display with avatars

Current implementation: `lib/core/features/connection/`
New schema: `./organisation/DATABASE_SCHEMA_V2.md`

@CLAUDE.md for coding patterns and architecture
</context>

<research>
Before implementing, examine:
1. Current connection feature structure in `lib/core/features/connection/`
2. Current DTOs, models, services, and use cases
3. How friend avatars are currently fetched and displayed
4. The new schema design from Phase 1
5. Any RPC functions used (`join_circle_transaction`, etc.)
</research>

<requirements>
1. **Update DTOs and Models**
   - Align with new `friendships` table schema
   - Update Freezed models for new field names/types
   - Ensure JSON serialization matches new schema

2. **Update Services**
   - Implement efficient friend list fetching with new indexes
   - Add "friends currently locked out" query
   - Optimize "is user my friend?" check
   - Keep invite code logic (phone number based, 72h expiry)

3. **Implement Caching Strategy**
   - Cache friend list locally with invalidation triggers
   - Cache avatar URLs with TTL (signed URLs expire)
   - Use Supabase Realtime for friend list changes OR efficient polling

4. **Avatar Loading Optimization**
   - Batch fetch avatar URLs instead of sequential
   - Implement progressive loading for friends list
   - Cache avatar URLs client-side with appropriate TTL

5. **Update Use Cases**
   - Refactor to use new service methods
   - Maintain Result<T> pattern
   - Keep 150 limit enforcement

**CRITICAL Scalability Fixes (must include):**

6. **Batch Avatar Fetching (HIGH PRIORITY)**
   - Replace sequential avatar loop with `Future.wait()` batches
   - Max 15-20 concurrent requests to avoid overwhelming the server
   - Reference pattern: `post_enrichment_service.dart`
   - Example:
     ```dart
     // BAD - sequential
     for (final friend in friends) {
       friend.avatarUrl = await getSignedUrl(friend.avatarPath);
     }

     // GOOD - batched parallel
     final batches = friends.chunked(15);
     for (final batch in batches) {
       await Future.wait(batch.map((f) => getSignedUrl(f.avatarPath)));
     }
     ```

7. **Connection Caching with Background Preload**
   - Add `FriendsCacheProvider` with `keepAlive: true`
   - Preload friend list on app start (background, non-blocking)
   - 10-minute TTL with app-resume refresh
   - Max 150 friends (Dunbar's number enforces natural limit)
   - Structure:
     ```dart
     FriendsCacheState {
       List<FriendModel> friends;
       Map<String, String> avatarUrls;  // userId -> signedUrl
       DateTime lastFetchedAt;
     }
     ```

8. **Avatar URL Caching**
   - Cache signed URLs for 50 minutes (before 1h expiry)
   - Store in memory with friend data
   - Refresh on app resume, not on every view
   - Invalidate specific avatar when user updates their profile
</requirements>

<implementation>
Follow existing patterns from @CLAUDE.md:
- Feature structure: data/ (DTOs, services, mappers) + domain/ (models, use cases, providers)
- Use `SupabaseResultProcessor` mixin for all Supabase calls
- Freezed for all models, Riverpod for state management
- Result<T> pattern for all async operations

Specific optimizations:
- Parallel avatar URL fetching (not sequential)
- Consider storing avatar URLs in profiles table (denormalized) to avoid separate storage lookups
- Use Supabase's `in` filter for batch queries
</implementation>

<output>
Modify these files (do not create new files unless absolutely necessary):

In `lib/core/features/connection/`:
- `data/dtos/` - Update DTOs for new schema
- `data/mappers/` - Update mappers
- `data/services/` - Update service methods with optimized queries
- `domain/models/` - Update Freezed models
- `domain/use_cases/` - Update use cases
- `domain/providers/` - Update providers if needed

After changes, list:
- Files modified
- New queries added
- Caching strategy implemented
- Breaking changes requiring UI updates
</output>

<constraints>
- Do NOT change the UI layer in this phase
- Do NOT add new packages
- Maintain backward compatibility where possible during transition
- Keep the existing feature folder structure
- Run build_runner after model changes (note in summary)
</constraints>

<verification>
Before completing:
1. All DTOs match new schema field names and types
2. Friend list query uses new indexes
3. Avatar fetching is batched/parallel, not sequential
4. 150 friend limit still enforced
5. Invite code flow still works
6. No Flutter imports in data/services layer
</verification>

<success_criteria>
- Connection feature uses new database schema
- Friend list loads efficiently with cached avatars
- "Friends currently locked out" query is fast
- Code follows existing patterns from CLAUDE.md
</success_criteria>
