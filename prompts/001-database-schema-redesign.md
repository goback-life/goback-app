<objective>
Design a complete, scalable database schema from scratch for the Goback app refactor.

This is Phase 1 of a major refactoring effort. The new schema must support millions of users efficiently while simplifying the data model to focus on the core lockout-based social experience.
</objective>

<context>
Goback is a social app where users lock themselves out of social media, notify friends, and post what they did during lockouts. Key constraints:
- Maximum 150 friends per user (Dunbar's number)
- Posts only created after completing a lockout
- 24-hour feed expiration
- Bidirectional friendships (mutual consent required)
- Phone number-based friend discovery

Current tech stack: Supabase (PostgreSQL), Flutter frontend

Review these files for current schema understanding:
@organisation/REFACTOR_ANALYSIS.md
@CLAUDE.md
</context>

<research>
Before designing, examine the current database structure:
1. Find all Supabase migration files in `db/` or `supabase/migrations/`
2. Examine current DTOs in `lib/core/features/*/data/dtos/` to understand current data shapes
3. Review RPC functions mentioned in services (especially `get_user_feed`, `join_circle_transaction`)
4. Check `lib/core/features/connection/` for current friend relationship implementation
5. Check `lib/core/features/lockout/` for current lockout data model
</research>

<requirements>
Design schemas for these core entities:

1. **profiles** - User accounts
   - Optimize for: profile lookups, phone number search, friend list queries
   - Include: weekly_lockout_minutes stat (computed or stored)
   - Consider: avatar URL caching strategy

2. **friendships** - Bidirectional friend relationships
   - Must be bidirectional (A friends B = B friends A)
   - Enforce 150 friend limit at database level
   - Optimize for: "get all friends", "is X my friend?", "friends currently locked out"

3. **lockout_sessions** - Active and historical lockouts
   - Track: initiator, duration, optional action text, location, participants (joiners)
   - Link to resulting post when lockout completes
   - Optimize for: "who in my network is locked out now?", "my lockout history"

4. **posts** - Lockout completion posts only
   - Only created after lockout ends
   - Media attachments (photo/video)
   - Tag participants (lockout initiator + joiners)
   - 24h TTL for feed visibility
   - Optimize for: chronological feed of friends' posts

5. **post_media** - Media attachments for posts
   - Support photo and video
   - Storage path references
   - Video duration constraint: `duration_seconds INTEGER CHECK (duration_seconds <= 60)` for videos
   - Enforce 60-second max at database level

6. **invite_codes** - Friend invitation system
   - Phone number based
   - Expiration (72h current)
</requirements>

<scalability_requirements>
Design for 1M+ users where:
- Each user has up to 150 friends
- Average 2-3 lockouts per user per day
- Feed queries happen every app open (high read volume)
- Lockout status checks happen frequently during active lockouts

Include:
- Appropriate indexes for common query patterns
- Partitioning strategy if beneficial (e.g., time-based for posts)
- Denormalization decisions with rationale
- Row-level security (RLS) policies for Supabase

**CRITICAL Scalability Fixes (must include):**

1. **Denormalized counts on posts table**
   - Add `reaction_count INTEGER DEFAULT 0`
   - Add `comment_count INTEGER DEFAULT 0`
   - Create triggers to update counts on insert/delete
   - Rationale: Eliminates N+2 subqueries per feed load

2. **Optimized friendship index**
   - Add normalized index: `CREATE INDEX idx_friendships_pair ON friendships((LEAST(user_a_id, user_b_id)), (GREATEST(user_a_id, user_b_id)))`
   - Rationale: Eliminates OR clause double-lookup for bidirectional queries

3. **Compound notification index**
   - Add: `CREATE INDEX idx_notifications_mark_read ON notifications(user_id, notification_type, reference_id, read_at)`
   - Rationale: Optimizes mark-as-read batch operations

4. **Avatar URL denormalization consideration**
   - Consider storing avatar_url directly in relevant tables to avoid signed URL fetching at query time
   - Document trade-offs: storage duplication vs query performance
</scalability_requirements>

<output>
Create a comprehensive schema document:

Save to: `./organisation/DATABASE_SCHEMA_V2.md`

Structure:
1. **Entity Relationship Diagram** (ASCII or mermaid)
2. **Table Definitions** - Full CREATE TABLE statements with:
   - Column types and constraints
   - Primary/foreign keys
   - Indexes with rationale
   - RLS policies
3. **Key Queries** - SQL for common operations showing how indexes are used:
   - Get user's feed (friends' posts from last 24h)
   - Get friends currently locked out
   - Check if two users are friends
   - Get user's lockout history for calendar
4. **Migration Strategy** - How to migrate from current schema
5. **Computed Fields** - Strategy for weekly_lockout_minutes and similar stats
6. **Caching Strategy** - What to cache client-side vs server-side

Also create the actual migration file:
Save to: `./db/migrations/001_schema_v2.sql`
</output>

<constraints>
- Do NOT include tables for features being removed (time_limit, link_preview, non-lockout posts)
- Keep the schema as simple as possible while meeting requirements
- Prefer PostgreSQL native features over application-level logic
- All timestamps in UTC with timezone
- Use UUIDs for primary keys (Supabase convention)
- Include soft-delete capability where data retention matters
</constraints>

<success_criteria>
- Schema supports all four core features: friends, lockouts, posts, profiles
- Common queries can be answered with single indexed lookups or simple JOINs
- 150 friend limit enforced at DB level
- Clear migration path from current schema documented
- RLS policies ensure users only see appropriate data
</success_criteria>
