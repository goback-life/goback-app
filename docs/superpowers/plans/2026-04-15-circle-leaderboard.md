# Circle Leaderboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the alphabetical circle friend list with a leaderboard ranked by average lockout duration (rolling 7 days), using an inverted scroll where #1 sits at the bottom.

**Architecture:** Supabase RPC function aggregates `lockout_completed_log` data for circle members, returns pre-sorted leaderboard entries. Flutter side: new DTO, service method, provider, and modified circle view/tile components.

**Tech Stack:** Flutter/Dart (FVM), Supabase (RPC, migrations), Riverpod, Freezed

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260415190000_circle_leaderboard.sql` | RPC function + composite index |
| Create | `lib/core/features/connection/data/dtos/leaderboard_entry_dto.dart` | Freezed DTO for RPC response |
| Modify | `lib/core/features/connection/domain/contracts/connection_service_contract.dart` | Add `getCircleLeaderboard()` to contract |
| Modify | `lib/core/features/connection/data/services/connection_service.dart` | Implement `getCircleLeaderboard()` |
| Create | `lib/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart` | Riverpod provider for leaderboard data |
| Create | `lib/presentation/pages/your_circle/components/leaderboard_tile.dart` | Leaderboard tile with rank/duration/variants |
| Modify | `lib/presentation/pages/your_circle/views/your_circle_view.dart` | Swap alphabetical list for leaderboard |
| Modify | `lib/presentation/pages/your_circle/your_circle_layout.dart` | Add leaderboard layout constants |

---

### Task 1: Supabase Migration — RPC Function + Index

**Files:**
- Create: `supabase/migrations/20260415190000_circle_leaderboard.sql`

**Context:** The `lockout_completed_log` table already stores per-user `duration_minutes` and `goback_score` per session with an index on `(user_id, session_date)`. This is more efficient than computing durations from `lockout_participants.joined_at/left_at`. The `get_user_friends()` pattern shows how to query friendships. RLS on `lockout_completed_log` only allows reading own rows, so this function must be `SECURITY DEFINER`.

- [ ] **Step 1: Create migration file**

```sql
-- ============================================================================
-- MIGRATION 019: Circle Leaderboard RPC
-- ============================================================================
-- Adds get_circle_leaderboard() function that returns circle members ranked
-- by average lockout duration over a rolling 7-day window.
-- Uses lockout_completed_log (pre-computed durations, indexed on user_id+date).
-- ============================================================================

-- Composite index for efficient 7-day range scans per user
CREATE INDEX IF NOT EXISTS idx_lockout_log_user_date_duration
  ON lockout_completed_log (user_id, session_date, duration_minutes);

CREATE OR REPLACE FUNCTION get_circle_leaderboard()
RETURNS TABLE (
  user_id       UUID,
  username      TEXT,
  avatar_url    TEXT,
  avg_duration_minutes DOUBLE PRECISION,
  session_count INT,
  is_current_user BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_cutoff  DATE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  v_cutoff := (NOW() - INTERVAL '7 days')::date;

  RETURN QUERY
  WITH circle_members AS (
    -- All friends + self
    SELECT prof.id AS member_id, prof.username, prof.avatar_url
    FROM friendships f
    JOIN profiles prof ON (
      CASE
        WHEN f.user_a_id = v_user_id THEN f.user_b_id = prof.id
        ELSE f.user_a_id = prof.id
      END
    )
    WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id

    UNION ALL

    -- Include the current user
    SELECT p.id, p.username, p.avatar_url
    FROM profiles p
    WHERE p.id = v_user_id
  ),
  stats AS (
    SELECT
      cm.member_id,
      cm.username,
      cm.avatar_url,
      AVG(lcl.duration_minutes)::DOUBLE PRECISION AS avg_dur,
      COUNT(lcl.id)::INT AS sess_count
    FROM circle_members cm
    LEFT JOIN lockout_completed_log lcl
      ON lcl.user_id = cm.member_id
      AND lcl.session_date >= v_cutoff
    GROUP BY cm.member_id, cm.username, cm.avatar_url
  )
  SELECT
    s.member_id AS user_id,
    s.username,
    s.avatar_url,
    s.avg_dur AS avg_duration_minutes,
    s.sess_count AS session_count,
    (s.member_id = v_user_id) AS is_current_user
  FROM stats s
  ORDER BY s.avg_dur DESC NULLS LAST, s.username ASC;
END;
$$;
```

- [ ] **Step 2: Push migration to local Supabase**

Run: `supabase db reset` (if running locally) or `supabase migration up`
Expected: Migration applies without errors.

- [ ] **Step 3: Verify the function works**

Run in Supabase SQL editor or psql:
```sql
-- Test with a known user ID (replace with actual test user)
SELECT * FROM get_circle_leaderboard();
```
Expected: Returns rows with user_id, username, avatar_url, avg_duration_minutes (NULL for inactive), session_count, is_current_user.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260415190000_circle_leaderboard.sql
git commit -m "feat: add get_circle_leaderboard RPC function"
```

---

### Task 2: Leaderboard Entry DTO

**Files:**
- Create: `lib/core/features/connection/data/dtos/leaderboard_entry_dto.dart`

**Context:** Follow the pattern in `get_circle_members_response_dto.dart` — Freezed sealed class with `@JsonKey` for snake_case column names. The RPC returns `user_id`, `username`, `avatar_url`, `avg_duration_minutes`, `session_count`, `is_current_user`.

- [ ] **Step 1: Create the DTO file**

```dart
// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'leaderboard_entry_dto.freezed.dart';
part 'leaderboard_entry_dto.g.dart';

@freezed
sealed class LeaderboardEntryDto with _$LeaderboardEntryDto {
  const factory LeaderboardEntryDto({
    @JsonKey(name: 'user_id') required String userId,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'avg_duration_minutes') double? avgDurationMinutes,
    @JsonKey(name: 'session_count') @Default(0) int sessionCount,
    @JsonKey(name: 'is_current_user') @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntryDto;

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryDtoFromJson(json);
}
```

- [ ] **Step 2: Run build_runner to generate Freezed code**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `leaderboard_entry_dto.freezed.dart` and `leaderboard_entry_dto.g.dart` without errors.

- [ ] **Step 3: Verify it compiles**

Run: `fvm flutter analyze lib/core/features/connection/data/dtos/leaderboard_entry_dto.dart`
Expected: No errors (warnings from pre-existing issues are OK).

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/connection/data/dtos/leaderboard_entry_dto.dart
git commit -m "feat: add LeaderboardEntryDto model"
```

---

### Task 3: Service Contract + Implementation

**Files:**
- Modify: `lib/core/features/connection/domain/contracts/connection_service_contract.dart`
- Modify: `lib/core/features/connection/data/services/connection_service.dart`

**Context:** The contract is at `lib/core/features/connection/domain/contracts/connection_service_contract.dart`. The implementation is `ConnectionService` at `lib/core/features/connection/data/services/connection_service.dart`. Follow existing patterns: `FutureResult<T>` return, try/catch with `Result.success`/`Result.failure`, RPC called via `supabase.rpc('function_name')` cast to `List<dynamic>`.

- [ ] **Step 1: Add method to contract**

Add this import at the top of `connection_service_contract.dart`:

```dart
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
```

Add this method to the `ConnectionServiceContract` abstract class, after the `getCircleMembers()` method:

```dart
  /// Retrieves circle leaderboard ranked by average lockout duration
  /// over a rolling 7-day window. Includes current user in results.
  FutureResult<List<LeaderboardEntryDto>> getCircleLeaderboard();
```

- [ ] **Step 2: Implement in ConnectionService**

Add this import at the top of `connection_service.dart` (if not already present):

```dart
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
```

Add this method to the `ConnectionService` class:

```dart
  @override
  FutureResult<List<LeaderboardEntryDto>> getCircleLeaderboard() async {
    try {
      final result =
          await supabase.rpc('get_circle_leaderboard') as List<dynamic>;

      final entries = result.map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        return LeaderboardEntryDto.fromJson(data);
      }).toList();

      return Result.success(entries);
    } catch (e) {
      logger.error('Error getting circle leaderboard', exception: e);
      final exception =
          e is Exception ? e : Exception('Failed to get circle leaderboard: $e');
      return Result.failure(exception);
    }
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `fvm flutter analyze lib/core/features/connection/`
Expected: No new errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/connection/domain/contracts/connection_service_contract.dart lib/core/features/connection/data/services/connection_service.dart
git commit -m "feat: add getCircleLeaderboard to connection service"
```

---

### Task 4: Riverpod Provider

**Files:**
- Create: `lib/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart`

**Context:** Follow the pattern in `get_circle_members_provider.dart` — `@Riverpod(keepAlive: false)` class extending generated `_$` base. Use `ref.watch(connectionServiceProvider)` to get the service. Return `Result<List<LeaderboardEntryDto>>`. The provider also enriches entries with avatar URLs using the same mechanism as circle members.

- [ ] **Step 1: Create the provider file**

```dart
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_circle_leaderboard_provider.g.dart';

@Riverpod(keepAlive: false)
class GetCircleLeaderboard extends _$GetCircleLeaderboard {
  @override
  Future<Result<List<LeaderboardEntryDto>>> build() async {
    final service = ref.watch(connectionServiceProvider);
    return service.getCircleLeaderboard();
  }
}
```

- [ ] **Step 2: Run build_runner to generate provider code**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `get_circle_leaderboard_provider.g.dart` without errors.

- [ ] **Step 3: Verify it compiles**

Run: `fvm flutter analyze lib/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart
git commit -m "feat: add getCircleLeaderboard Riverpod provider"
```

---

### Task 5: Layout Constants + Leaderboard Tile Widget

**Files:**
- Modify: `lib/presentation/pages/your_circle/your_circle_layout.dart`
- Create: `lib/presentation/pages/your_circle/components/leaderboard_tile.dart`

**Context:** The existing `your_circle_friend_tile.dart` uses these constants from `YourCircleLayout` mixin: `friendTileHeight` (59), `friendAvatarSize` (39), `friendAvatarToText` (10), `friendTextSize` (24), `friendLetterSpacing` (-1.44). Font is `MainFontFamilies.quicksand`, colors from `MainColors`. The tile has no background/border — it's a bare Row on the dark scaffold.

Read `your_circle_layout.dart` and `your_circle_friend_tile.dart` before starting to confirm exact patterns.

- [ ] **Step 1: Add leaderboard constants to layout mixin**

Read `lib/presentation/pages/your_circle/your_circle_layout.dart` to find the mixin. Add these constants to the `YourCircleLayout` mixin:

```dart
  // Leaderboard
  static const double kingTileHeight = 66.0;
  static const double kingAvatarSize = 42.0;
  static const double rankWidth = 28.0;
  static const double rankRightMargin = 10.0;
  static const double accentBarWidth = 3.0;
  static const double accentBarHeight = 28.0;
  static const double kingAccentBarHeight = 32.0;
  static const double accentBarLeftOffset = 14.0;
```

- [ ] **Step 2: Create the leaderboard tile widget**

Create `lib/presentation/pages/your_circle/components/leaderboard_tile.dart`. This widget renders a single leaderboard entry. It handles four variants: regular, current user, king (#1), and inactive (no sessions). Read the existing `your_circle_friend_tile.dart` and match its structure (Row-based, same indent pattern, same avatar widget).

```dart
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/style/main_colors.dart';
import 'package:cloudless/presentation/style/main_font_families.dart';
import 'package:flutter/material.dart';

class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile({
    required this.entry,
    required this.rank,
    required this.onTap,
    super.key,
  });

  final LeaderboardEntryDto entry;
  final int rank;
  final VoidCallback? onTap;

  bool get _isKing => rank == 1 && entry.avgDurationMinutes != null;
  bool get _isInactive => entry.sessionCount == 0;

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftIndent = screenWidth * 0.1;
    final tileHeight =
        _isKing ? YourCircleLayout.kingTileHeight : YourCircleLayout.friendTileHeight;
    final avatarSize =
        _isKing ? YourCircleLayout.kingAvatarSize : YourCircleLayout.friendAvatarSize;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: tileHeight,
        child: Stack(
          children: [
            // Accent bar for king or current user
            if (_isKing || entry.isCurrentUser)
              Positioned(
                left: leftIndent - YourCircleLayout.accentBarLeftOffset,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: YourCircleLayout.accentBarWidth,
                    height: _isKing
                        ? YourCircleLayout.kingAccentBarHeight
                        : YourCircleLayout.accentBarHeight,
                    decoration: BoxDecoration(
                      color: _isKing
                          ? _gold.withValues(alpha: 0.5)
                          : MainColors.accent.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            // Main row
            Padding(
              padding: EdgeInsets.only(left: leftIndent),
              child: Row(
                children: [
                  // Rank
                  _buildRank(),
                  SizedBox(width: YourCircleLayout.rankRightMargin),
                  // Avatar
                  _Avatar(
                    username: entry.username,
                    avatarUrl: entry.avatarUrl,
                    size: avatarSize,
                    dimmed: _isInactive,
                    isKing: _isKing,
                  ),
                  SizedBox(width: YourCircleLayout.friendAvatarToText),
                  // Username
                  Expanded(child: _buildUsername()),
                  // Duration
                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.1),
                    child: _buildDuration(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRank() {
    if (_isKing) {
      return SizedBox(
        width: YourCircleLayout.rankWidth,
        child: Text(
          '\u2654', // ♔ crown
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _gold.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return SizedBox(
      width: YourCircleLayout.rankWidth,
      child: Text(
        '#$rank',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
          color: MainColors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildUsername() {
    Color color;
    FontWeight weight;

    if (_isKing) {
      color = _gold.withValues(alpha: 0.75);
      weight = FontWeight.w600;
    } else if (entry.isCurrentUser) {
      color = MainColors.accent;
      weight = FontWeight.w600;
    } else if (_isInactive) {
      color = MainColors.white.withValues(alpha: 0.4);
      weight = FontWeight.w500;
    } else {
      color = MainColors.white;
      weight = FontWeight.w500;
    }

    return Text(
      entry.isCurrentUser ? 'you' : entry.username,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: MainFontFamilies.quicksand,
        fontSize: YourCircleLayout.friendTextSize,
        fontWeight: weight,
        letterSpacing: YourCircleLayout.friendLetterSpacing,
        color: color,
      ),
    );
  }

  Widget _buildDuration() {
    if (_isInactive) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\u2014', // em dash
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MainColors.white.withValues(alpha: 0.25),
            ),
          ),
          Text(
            'no sessions',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 10,
              color: MainColors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      );
    }

    final minutes = entry.avgDurationMinutes ?? 0;
    final formatted = _formatDuration(minutes);

    Color color;
    FontWeight weight;

    if (_isKing) {
      color = _gold.withValues(alpha: 0.6);
      weight = FontWeight.w600;
    } else if (entry.isCurrentUser) {
      color = MainColors.accent.withValues(alpha: 0.7);
      weight = FontWeight.w500;
    } else {
      color = MainColors.white.withValues(alpha: 0.5);
      weight = FontWeight.w500;
    }

    return Text(
      formatted,
      style: TextStyle(
        fontFamily: MainFontFamilies.quicksand,
        fontSize: 14,
        fontWeight: weight,
        letterSpacing: -0.5,
        color: color,
      ),
    );
  }

  static String _formatDuration(double minutes) {
    final totalMinutes = minutes.round();
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.username,
    required this.avatarUrl,
    required this.size,
    required this.dimmed,
    required this.isKing,
  });

  final String username;
  final String? avatarUrl;
  final double size;
  final bool dimmed;
  final bool isKing;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final bgColor = dimmed
        ? MainColors.accent.withValues(alpha: 0.3)
        : MainColors.accent;

    Widget avatar;
    if (hasImage) {
      avatar = ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _letterAvatar(bgColor),
        ),
      );
    } else {
      avatar = _letterAvatar(bgColor);
    }

    if (isKing) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              blurRadius: 20,
            ),
          ],
        ),
        child: avatar,
      );
    }

    return SizedBox(width: size, height: size, child: avatar);
  }

  Widget _letterAvatar(Color bgColor) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w500,
          fontSize: size * 0.4,
          color: MainColors.white,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `fvm flutter analyze lib/presentation/pages/your_circle/components/leaderboard_tile.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/your_circle/your_circle_layout.dart lib/presentation/pages/your_circle/components/leaderboard_tile.dart
git commit -m "feat: add leaderboard tile widget with king/user/inactive variants"
```

---

### Task 6: Wire Up Circle View to Use Leaderboard

**Files:**
- Modify: `lib/presentation/pages/your_circle/views/your_circle_view.dart`

**Context:** The current `your_circle_view.dart` uses the `useCircleMembers(ref)` hook which returns `CircleMembersData` with alphabetically grouped members. It renders a reversed `ListView` with `YourCircleFriendTile` widgets. We need to swap the data source to use `getCircleLeaderboardProvider` and render `LeaderboardTile` widgets instead, while preserving search, remove mode, swipe-to-delete, and the bottom bar.

Read `lib/presentation/pages/your_circle/views/your_circle_view.dart` in full before making changes. The key modifications are:

1. Watch `getCircleLeaderboardProvider` instead of (or alongside) `getCircleMembersProvider`
2. Replace the letter-grouped member list with a flat ranked list
3. Replace `YourCircleFriendTile` with `LeaderboardTile`
4. Keep search filtering (filter leaderboard entries by username)
5. Keep remove mode, swipe-to-delete, and bottom bar unchanged

- [ ] **Step 1: Read the current view file**

Read `lib/presentation/pages/your_circle/views/your_circle_view.dart` in full to understand the current structure, hook usage, and build method.

- [ ] **Step 2: Add imports**

Add these imports to `your_circle_view.dart`:

```dart
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_leaderboard_provider.dart';
import 'package:cloudless/presentation/pages/your_circle/components/leaderboard_tile.dart';
```

- [ ] **Step 3: Watch the leaderboard provider**

In the build method, add a watch on the leaderboard provider alongside the existing circle members provider (which is still needed for remove mode and swipe-to-delete — those operate on `ProfileModel`/friendship IDs):

```dart
final leaderboardAsync = ref.watch(getCircleLeaderboardProvider);
```

- [ ] **Step 4: Replace the list body**

Replace the ListView section that renders `YourCircleFriendTile` with one that renders `LeaderboardTile`. The ListView remains `reverse: true`. The search filter should apply to leaderboard entries by username. The remove mode should continue working with the existing friendship-based data.

When in **normal mode** (not remove mode), render leaderboard entries:

```dart
// Inside the ListView builder, for normal (non-remove) mode:
// Filter leaderboard entries by search query
final filteredEntries = leaderboardEntries.where((entry) {
  if (searchQuery.isEmpty) return true;
  return entry.username.toLowerCase().contains(searchQuery.toLowerCase());
}).toList();

// Build tiles — rank is index+1 since list is already sorted by the RPC
for (var i = 0; i < filteredEntries.length; i++) {
  final entry = filteredEntries[i];
  final rank = i + 1;
  children.add(
    LeaderboardTile(
      entry: entry,
      rank: rank,
      onTap: () => _navigateToProfile(context, entry.userId),
    ),
  );
}
```

When in **remove mode**, fall back to the existing alphabetical friend tiles (remove mode needs friendship IDs and checkbox selection which the leaderboard DTO doesn't carry).

- [ ] **Step 5: Handle loading and error states**

Use the `leaderboardAsync` state to show loading/error. Follow the existing pattern in the file for `AsyncValue` handling:

```dart
leaderboardAsync.when(
  loading: () => /* existing loading widget */,
  error: (error, stack) => /* existing error widget */,
  data: (result) => result.fold(
    (entries) => /* build the leaderboard list */,
    (error) => /* existing error widget */,
  ),
);
```

- [ ] **Step 6: Verify it compiles**

Run: `fvm flutter analyze lib/presentation/pages/your_circle/views/your_circle_view.dart`
Expected: No new errors.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/pages/your_circle/views/your_circle_view.dart
git commit -m "feat: replace alphabetical circle list with leaderboard"
```

---

### Task 7: Build, Analyze, Smoke Test

**Files:** None new — verification only.

- [ ] **Step 1: Run build_runner to ensure all generated code is current**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: Completes without errors. All `.g.dart` and `.freezed.dart` files generated.

- [ ] **Step 2: Run analyzer**

Run: `fvm flutter analyze`
Expected: No new errors (pre-existing warnings with `--no-fatal-warnings` are OK).

- [ ] **Step 3: Run tests**

Run: `fvm flutter test`
Expected: All existing tests pass. No regressions.

- [ ] **Step 4: Push migration to stage**

Push `20260415190000_circle_leaderboard.sql` to the goback-stage Supabase project. Update `memory/project_stage_migrations.md` with the migration name and date.

- [ ] **Step 5: Run the app and verify**

Run: `fvm flutter run --flavor production`
Navigate to the Circle tab. Verify:
- Leaderboard loads with ranked entries
- #1 at bottom has gold name and crown
- Current user highlighted in blue
- Inactive friends show dash
- Search filters the leaderboard
- Scroll starts at bottom (king visible)
- Swipe-to-delete still works
- Remove mode still works
- Tapping a tile navigates to profile

- [ ] **Step 6: Final commit if any fixups needed**

```bash
git add -A
git commit -m "fix: leaderboard integration fixups"
```
