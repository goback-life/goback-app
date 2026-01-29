# Database Schema V2

## Overview

This document describes the redesigned Goback database schema, optimized for the lockout-based social experience with 11 tables (down from 12).

### Key Changes from V1
- `connections` replaced by `friendships` (ordered UUIDs, single row per friendship)
- `calendar_posts` table removed (replaced by `calendar_saved_at` column on posts)
- `post_exclusions` table removed (replaced by `excluded_user_ids` array on posts)
- `post_reports` deferred to admin tooling
- New `lockout_sessions` table for tracking lockouts
- New `post_comments` table for text comments
- New `notifications` table with aggregated summaries
- Simplified `posts` table (lockout-centric, no parent_id)

---

## Tables

### 1. profiles

User profile information linked to Supabase auth.users.

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  biography TEXT,
  avatar_url TEXT,                              -- Denormalized, no storage lookup needed
  weekly_lockout_minutes INT DEFAULT 0,         -- Trigger-updated stat
  notifications_checked_at TIMESTAMPTZ,         -- For computing unread counts
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT username_length CHECK (char_length(username) <= 30),
  CONSTRAINT bio_length CHECK (biography IS NULL OR char_length(biography) <= 200)
);

CREATE UNIQUE INDEX profiles_username_unique_ci ON profiles (LOWER(username));
```

**New columns:**
- `avatar_url` - Direct URL to avatar, eliminates storage lookup
- `weekly_lockout_minutes` - Running total, updated by trigger when lockout ends
- `notifications_checked_at` - Last time user opened notification feed

---

### 2. friendships

Bidirectional friendships with ordered UUIDs (replaces `connections`).

```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Enforces user_a_id < user_b_id to prevent duplicate friendships
  CONSTRAINT friendship_ordered CHECK (user_a_id < user_b_id),
  CONSTRAINT friendship_unique UNIQUE (user_a_id, user_b_id)
);

CREATE INDEX idx_friendships_user_a ON friendships (user_a_id);
CREATE INDEX idx_friendships_user_b ON friendships (user_b_id);
```

**Key design:**
- Single row per friendship (not two bidirectional rows)
- `user_a_id < user_b_id` constraint prevents duplicates
- Query pattern: `WHERE user_a_id = $id OR user_b_id = $id`

---

### 3. lockout_sessions

Tracks user lockout sessions with optional location and participants.

```sql
CREATE TABLE lockout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  action_text TEXT,                             -- "Going for a walk"
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  location_name TEXT,
  participants UUID[] DEFAULT '{}',             -- Friends who joined
  post_id UUID REFERENCES posts(id),            -- Linked when lockout ends (nullable)

  CONSTRAINT action_text_length CHECK (action_text IS NULL OR char_length(action_text) <= 100)
);

CREATE INDEX idx_lockout_sessions_user ON lockout_sessions (user_id);
CREATE INDEX idx_lockout_sessions_active ON lockout_sessions (user_id, ends_at)
  WHERE post_id IS NULL;  -- Partial index for active lockouts
```

**Lifecycle:**
1. User starts lockout -> row created with `post_id = NULL`
2. Friends can join -> added to `participants` array
3. Lockout ends -> user creates post -> `post_id` set
4. `weekly_lockout_minutes` updated via trigger

---

### 4. posts

Simplified post model, lockout-centric with inline exclusions.

```sql
CREATE TYPE content_type AS ENUM ('image', 'video');

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  lockout_id UUID REFERENCES lockout_sessions(id),
  thumbnail_url TEXT NOT NULL,
  thumbnail_width INT NOT NULL,
  thumbnail_height INT NOT NULL,
  content_type content_type NOT NULL,
  description TEXT,
  published_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  published_timezone TEXT DEFAULT 'UTC' NOT NULL,
  calendar_saved_at TIMESTAMPTZ,                -- NULL = pending, SET = permanent
  excluded_user_ids UUID[] DEFAULT '{}',        -- Inline exclusions (no separate table)
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT description_length CHECK (description IS NULL OR char_length(description) <= 500)
);

CREATE INDEX idx_posts_author ON posts (author_id);
CREATE INDEX idx_posts_lockout ON posts (lockout_id);
CREATE INDEX idx_posts_published ON posts (published_at DESC);
CREATE INDEX idx_posts_calendar ON posts (author_id, calendar_saved_at)
  WHERE calendar_saved_at IS NOT NULL;  -- Partial index for calendar posts
CREATE INDEX idx_posts_pending ON posts (author_id, published_at)
  WHERE calendar_saved_at IS NULL;      -- Partial index for pending selection
```

**Removed from V1:**
- `parent_id` - No reply posts, only lockout posts
- `status` enum - All posts are published (drafts handled client-side)
- `content_date` - Use `published_at` date instead
- `deleted_at` - Non-saved posts are hard deleted

**New columns:**
- `lockout_id` - Links to the lockout session
- `calendar_saved_at` - When set, post is permanent
- `excluded_user_ids` - Array of users who cannot see this post

**Calendar selection:**
- Posts created during lockout have `calendar_saved_at = NULL`
- User selects best post within 24h of `published_at` -> sets `calendar_saved_at = NOW()`
- Max 1 saved post per user per calendar day
- Cleanup job deletes posts where `calendar_saved_at IS NULL AND published_at < NOW() - 24h`

---

### 5. post_media

Media files attached to posts (unchanged from V1).

```sql
CREATE TABLE post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL,                     -- 'image' or 'video'
  width INT,
  height INT,
  duration_seconds FLOAT,                       -- For video
  sort_order INT DEFAULT 0 NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT valid_sort_order CHECK (sort_order >= 0)
);

CREATE INDEX idx_post_media_post ON post_media (post_id);
CREATE UNIQUE INDEX idx_post_media_unique_type ON post_media (post_id, media_type);
```

---

### 6. post_tags

Users tagged in posts with denormalized display info.

```sql
CREATE TABLE post_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  tagged_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username TEXT NOT NULL,                       -- Denormalized for display
  avatar_url TEXT,                              -- Denormalized for display
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_post_tag UNIQUE (post_id, tagged_user_id)
);

CREATE INDEX idx_post_tags_post ON post_tags (post_id);
CREATE INDEX idx_post_tags_user ON post_tags (tagged_user_id);
```

**New columns:**
- `username` - Denormalized, avoids JOIN for display
- `avatar_url` - Denormalized, avoids JOIN for display

---

### 7. post_comments

Text comments on posts (NEW table).

```sql
CREATE TABLE post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ,                       -- Soft delete for comments

  CONSTRAINT content_length CHECK (char_length(content) <= 500)
);

CREATE INDEX idx_post_comments_post ON post_comments (post_id);
CREATE INDEX idx_post_comments_author ON post_comments (author_id);
CREATE INDEX idx_post_comments_created ON post_comments (post_id, created_at DESC);
```

**Design notes:**
- Text-only comments (no media)
- Single level (no nested replies to comments)
- Soft delete preserves history

---

### 8. post_reactions

Emoji reactions on posts (unchanged from V1).

```sql
CREATE TABLE post_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reaction TEXT NOT NULL,                       -- Emoji
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_user_post_reaction UNIQUE (post_id, user_id)
);

CREATE INDEX idx_post_reactions_post ON post_reactions (post_id);
CREATE INDEX idx_post_reactions_user ON post_reactions (user_id);
```

---

### 9. notifications

Aggregated notification summaries (NEW design).

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,                           -- See types below
  reference_id UUID NOT NULL,                   -- post_id, lockout_id, or friendship_id
  latest_actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  actor_count INT DEFAULT 1,                    -- Total actors
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  read_at TIMESTAMPTZ,                          -- NULL = unread

  CONSTRAINT unique_notification UNIQUE (user_id, type, reference_id)
);

CREATE INDEX idx_notifications_user ON notifications (user_id);
CREATE INDEX idx_notifications_unread ON notifications (user_id, updated_at DESC)
  WHERE read_at IS NULL;
```

**Notification types:**

| Type | Reference | Push? | Example Display |
|------|-----------|-------|-----------------|
| `reaction` | post_id | No | "John and 19 others reacted to your post" |
| `comment` | post_id | No | "John and 5 others commented on your post" |
| `tag` | post_id | No | "John tagged you in a post" |
| `lockout_started` | lockout_id | Yes | "John started a lockout" |
| `friend_joined` | friendship_id | Yes | "John joined your circle" |

**Aggregation behavior:**
- First event: INSERT with `actor_count = 1`
- Subsequent events on same reference: UPDATE `actor_count++`, `latest_actor_id = new_actor`, `updated_at = NOW()`, `read_at = NULL`
- User reads notifications: SET `read_at = NOW()`
- New activity after read: `read_at = NULL` (re-marks as unread)

**Display logic:**
- `actor_count = 1`: "John reacted to your post"
- `actor_count = 2`: "John and 1 other reacted to your post"
- `actor_count > 2`: "John and 19 others reacted to your post"

---

### 10. invite_codes

Invite codes for joining circles (unchanged from V1).

```sql
CREATE TABLE invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  used_by_id UUID REFERENCES profiles(id),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  used_at TIMESTAMPTZ
);

CREATE INDEX idx_invite_codes_creator ON invite_codes (creator_id);
CREATE INDEX idx_invite_codes_expires ON invite_codes (expires_at);
```

---

### 11. app_config

Application configuration key-value store (unchanged from V1).

```sql
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Tables Removed

| Table | Reason |
|-------|--------|
| `connections` | Replaced by `friendships` with ordered UUIDs |
| `calendar_posts` | Replaced by `calendar_saved_at` column on posts |
| `post_exclusions` | Replaced by `excluded_user_ids` array on posts |
| `post_reports` | Deferred to admin tooling |

---

## RPC Functions

### Feed & Discovery

#### `get_user_feed(cursor TIMESTAMPTZ, page_size INT)`
Returns friends' posts from last 24h, excluding where viewer is in `excluded_user_ids`.

```sql
SELECT p.*, prof.username, prof.avatar_url
FROM posts p
JOIN profiles prof ON p.author_id = prof.id
JOIN friendships f ON (
  (f.user_a_id = auth.uid() AND f.user_b_id = p.author_id) OR
  (f.user_b_id = auth.uid() AND f.user_a_id = p.author_id)
)
WHERE p.published_at > NOW() - INTERVAL '24 hours'
  AND NOT (auth.uid() = ANY(p.excluded_user_ids))
  AND (cursor IS NULL OR p.published_at < cursor)
ORDER BY p.published_at DESC
LIMIT page_size;
```

#### `get_user_calendar(target_user_id UUID, year INT, month INT)`
Returns saved calendar posts for a friend (or self).

```sql
SELECT p.*, prof.username, prof.avatar_url
FROM posts p
JOIN profiles prof ON p.author_id = prof.id
WHERE p.author_id = target_user_id
  AND p.calendar_saved_at IS NOT NULL
  AND EXTRACT(YEAR FROM p.published_at) = year
  AND EXTRACT(MONTH FROM p.published_at) = month
  AND NOT (auth.uid() = ANY(p.excluded_user_ids))
  AND (
    target_user_id = auth.uid()  -- Own calendar
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = auth.uid() AND f.user_b_id = target_user_id)
         OR (f.user_b_id = auth.uid() AND f.user_a_id = target_user_id)
    )
  )
ORDER BY p.published_at DESC;
```

#### `get_friends_locked_out()`
Returns friends with active lockouts.

```sql
SELECT ls.*, prof.username, prof.avatar_url
FROM lockout_sessions ls
JOIN profiles prof ON ls.user_id = prof.id
JOIN friendships f ON (
  (f.user_a_id = auth.uid() AND f.user_b_id = ls.user_id) OR
  (f.user_b_id = auth.uid() AND f.user_a_id = ls.user_id)
)
WHERE ls.ends_at > NOW()
  AND ls.post_id IS NULL  -- Active (not yet posted)
ORDER BY ls.started_at DESC;
```

### Calendar Management

#### `save_post_to_calendar(post_id UUID)`
Marks a post as the day's calendar selection (max 1 per day).

```sql
-- Verify ownership and within 24h window
-- Check no other post saved for this calendar day
-- Set calendar_saved_at = NOW()
```

### Friendship Management

#### `join_friendship_transaction(invite_code TEXT)`
Atomic friendship creation with 150 limit enforcement.

```sql
-- Verify invite code valid
-- Check neither user at 150 friends
-- Create friendship row (ordered UUIDs)
-- Mark invite as used
-- Create 'friend_joined' notification
```

#### `get_user_friends()`
Returns friend list with profile info.

```sql
SELECT prof.*
FROM profiles prof
JOIN friendships f ON (
  (f.user_a_id = auth.uid() AND f.user_b_id = prof.id) OR
  (f.user_b_id = auth.uid() AND f.user_a_id = prof.id)
)
ORDER BY prof.username;
```

### Lockout Management

#### `join_lockout_session(lockout_id UUID)`
Join a friend's active lockout.

```sql
-- Verify friendship exists
-- Verify lockout is active
-- Add auth.uid() to participants array
-- Create 'lockout_joined' notification for lockout owner
```

### Notifications

#### `upsert_notification(p_type TEXT, p_reference_id UUID, p_actor_id UUID)`
Insert or increment notification (called by triggers).

```sql
INSERT INTO notifications (user_id, type, reference_id, latest_actor_id, actor_count)
VALUES (p_recipient_id, p_type, p_reference_id, p_actor_id, 1)
ON CONFLICT (user_id, type, reference_id) DO UPDATE SET
  latest_actor_id = p_actor_id,
  actor_count = notifications.actor_count + 1,
  updated_at = NOW(),
  read_at = NULL;
```

#### `get_notification_feed()`
Returns aggregated notifications sorted by most recent activity.

```sql
SELECT n.*,
  actor.username AS latest_actor_username,
  actor.avatar_url AS latest_actor_avatar
FROM notifications n
JOIN profiles actor ON n.latest_actor_id = actor.id
WHERE n.user_id = auth.uid()
ORDER BY n.updated_at DESC
LIMIT 50;
```

### Cleanup

#### `cleanup_unsaved_posts()`
Deletes posts not saved to calendar after 24h window (scheduled job).

```sql
DELETE FROM posts
WHERE calendar_saved_at IS NULL
  AND published_at < NOW() - INTERVAL '24 hours';
```

---

## Triggers

### `trg_update_weekly_lockout_minutes`
When `lockout_sessions.post_id` is set (lockout ended), calculate duration and add to profile's `weekly_lockout_minutes`.

### `trg_notification_on_reaction`
When reaction inserted, call `upsert_notification('reaction', post_id, user_id)` for post author.

### `trg_notification_on_comment`
When comment inserted, call `upsert_notification('comment', post_id, author_id)` for post author.

### `trg_notification_on_tag`
When tag inserted, call `upsert_notification('tag', post_id, tagger_id)` for tagged user.

### `trg_notification_on_lockout_start`
When lockout starts, create `lockout_started` notification for all friends.

### `trg_profiles_updated_at`
Set `updated_at = NOW()` on profile update.

### `trg_posts_updated_at`
Set `updated_at = NOW()` on post update.

---

## Row Level Security (RLS)

### profiles
- SELECT: Anyone authenticated can view any profile
- INSERT: Only own profile (`auth.uid() = id`)
- UPDATE: Only own profile (`auth.uid() = id`)
- DELETE: Only own profile (`auth.uid() = id`)

### friendships
- SELECT: Either party can view (`auth.uid() IN (user_a_id, user_b_id)`)
- INSERT: Via `join_friendship_transaction` only (SECURITY DEFINER)
- DELETE: Either party can delete (`auth.uid() IN (user_a_id, user_b_id)`)

### lockout_sessions
- SELECT: Own sessions OR friends' active sessions
- INSERT: Only own sessions (`auth.uid() = user_id`)
- UPDATE: Only own sessions OR joining (adding to participants)

### posts
- SELECT: Own posts OR friends' posts (excluding where in `excluded_user_ids`)
- INSERT: Only own posts (`auth.uid() = author_id`)
- UPDATE: Only own posts (`auth.uid() = author_id`)
- DELETE: Only own posts (`auth.uid() = author_id`)

### post_comments
- SELECT: Via post visibility (if can see post, can see comments)
- INSERT: Only if can see the post (friends or author)
- UPDATE: Only own comments (`auth.uid() = author_id`)
- DELETE: Only own comments (soft delete)

### post_reactions
- SELECT: Anyone authenticated
- INSERT: Only if can see the post (friends or author)
- UPDATE: Only own reactions (`auth.uid() = user_id`)
- DELETE: Only own reactions (`auth.uid() = user_id`)

### notifications
- SELECT: Only own notifications (`auth.uid() = user_id`)
- INSERT: Via triggers only (SECURITY DEFINER functions)
- UPDATE: Only own notifications (for marking read)
- DELETE: Only own notifications

### invite_codes
- SELECT: Creator can see own codes, anyone can see valid unused codes
- INSERT: Only own codes (`auth.uid() = creator_id`)
- UPDATE: Via `join_friendship_transaction` only

---

## Migration Strategy

### Phase A: Add New Tables (parallel operation)
1. Create `friendships` table alongside `connections`
2. Create `lockout_sessions` table
3. Create `post_comments` table
4. Create `notifications` table
5. Add new columns to `profiles` and `posts`
6. Create new RPC functions with `_v2` suffix

### Phase B: Migrate Data
1. Copy `connections` -> `friendships` (deduplicate, order UUIDs)
2. Copy `calendar_posts` -> set `calendar_saved_at` on posts
3. Copy `post_exclusions` -> populate `excluded_user_ids` array

### Phase C: Switch Over
1. Update Flutter app to use new tables/RPCs
2. Enable new RLS policies
3. Rename `_v2` functions to replace old ones

### Phase D: Cleanup
1. Drop deprecated tables after verification period
2. Remove old RPC functions
3. Clean up old indexes

---

## Performance Considerations

### Indexes
- Partial indexes on active lockouts (`WHERE post_id IS NULL`)
- Partial indexes on calendar posts (`WHERE calendar_saved_at IS NOT NULL`)
- Partial indexes on unread notifications (`WHERE read_at IS NULL`)

### Query Patterns
- Feed: Uses `published_at` cursor pagination (no OFFSET)
- Calendar: Indexed by `(author_id, calendar_saved_at)`
- Friends: Single JOIN to friendships (no bidirectional lookup)

### Denormalization
- `avatar_url` in profiles (no storage lookup)
- `username`, `avatar_url` in post_tags (no JOIN for display)
- Aggregated notifications (one row per context, not per event)

### Array vs Table Trade-offs
- `excluded_user_ids` as array: Faster for small lists (<10), no JOIN needed
- `participants` as array: Typically small (<10 friends joining)
