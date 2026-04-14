import 'package:cloudless/core/features/lockout/data/dtos/lockout_activity_stats_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_monthly_summary_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_session_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing lockout sessions in the database.
class LockoutSessionService {
  const LockoutSessionService({required this.supabase});

  final SupabaseClient supabase;

  /// Creates a new lockout session.
  ///
  /// Returns the created session with its generated ID.
  FutureResult<LockoutSessionDto> createSession({
    required Duration duration,
    String? actionText,
    double? locationLat,
    double? locationLng,
    String? locationName,
    String? venueTagId,
    bool isOpenEnded = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now().toUtc();
      final endsAt = now.add(duration);

      final response = await supabase
          .from('lockout_sessions')
          .insert({
            'user_id': userId,
            'started_at': now.toIso8601String(),
            'ends_at': endsAt.toIso8601String(),
            'action_text': actionText,
            'location_lat': locationLat,
            'location_lng': locationLng,
            'location_name': locationName,
            'venue_tag_id': venueTagId,
            'is_open_ended': isOpenEnded,
          })
          .select()
          .single();

      return Result.success(LockoutSessionDto.fromJson(response));
    } catch (e) {
      logger.error('Failed to create lockout session', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to create lockout session: $e'),
      );
    }
  }

  /// Updates a lockout session with a post ID after the post is created.
  FutureResult<void> updateSessionPostId({
    required String sessionId,
    required String postId,
  }) async {
    try {
      await supabase
          .from('lockout_sessions')
          .update({'post_id': postId})
          .eq('id', sessionId);

      return Result.success(null);
    } catch (e) {
      logger.error('Failed to update lockout session post_id', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to update session: $e'),
      );
    }
  }

  /// Marks a lockout session as complete and updates weekly stats.
  ///
  /// [userStartedAt] - When THIS user started their lockout (may differ from
  /// session start for joiners). Pass null to use session's started_at.
  FutureResult<void> completeSessionWithoutPost(
    String sessionId, {
    DateTime? userStartedAt,
  }) async {
    try {
      await supabase.rpc(
        'complete_lockout_session',
        params: {
          'p_session_id': sessionId,
          'p_user_started_at': userStartedAt?.toUtc().toIso8601String(),
        },
      );
      return Result.success(null);
    } catch (e) {
      logger.warning('Failed to complete lockout session: $e');
      // Non-fatal - don't block the user
      return Result.failure(
        e is Exception ? e : Exception('Failed to complete session: $e'),
      );
    }
  }

  /// Updates weekly stats for a lockout session (used when post is created).
  ///
  /// Unlike completeSessionWithoutPost, this does NOT delete the session
  /// since the post needs to reference it.
  FutureResult<void> completeSessionWithStats(
    String sessionId, {
    DateTime? userStartedAt,
  }) async {
    try {
      await supabase.rpc(
        'update_lockout_weekly_stats',
        params: {
          'p_session_id': sessionId,
          'p_user_started_at': userStartedAt?.toUtc().toIso8601String(),
        },
      );
      return Result.success(null);
    } catch (e) {
      logger.warning('Failed to update weekly stats: $e');
      return Result.failure(
        e is Exception ? e : Exception('Failed to update stats: $e'),
      );
    }
  }

  /// Joins an existing lockout session.
  ///
  /// Calls the join_lockout_session RPC which adds the current user
  /// as a participant in the session.
  FutureResult<void> joinSession({required String sessionId}) async {
    try {
      final response = await supabase.rpc(
        'join_lockout_session',
        params: {'p_lockout_id': sessionId},
      );

      // RPC returns JSON with success/error fields
      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        if (!success) {
          final error = response['error'] as String? ?? 'Unknown error';
          return Result.failure(Exception(error));
        }
      }

      return Result.success(null);
    } catch (e) {
      logger.error('Failed to join lockout session', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to join lockout session: $e'),
      );
    }
  }

  /// Updates the goback score and raw signal data for a lockout session.
  FutureResult<void> updateScore({
    required String sessionId,
    required int score,
    bool? batteryWasCharging,
    int? stepCount,
  }) async {
    try {
      await supabase.rpc(
        'update_lockout_score',
        params: {
          'p_session_id': sessionId,
          'p_score': score,
          'p_battery_was_charging': batteryWasCharging,
          'p_step_count': stepCount,
        },
      );
      return Result.success(null);
    } catch (e) {
      logger.warning('Failed to update lockout score: $e');
      return Result.failure(
        e is Exception ? e : Exception('Failed to update score: $e'),
      );
    }
  }

  /// Gets the current user's active lockout session (if any).
  FutureResult<LockoutSessionDto?> getCurrentSession() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now().toUtc().toIso8601String();

      final response = await supabase
          .from('lockout_sessions')
          .select()
          .eq('user_id', userId)
          .gt('ends_at', now)
          .order('ends_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return Result.success(null);
      }

      return Result.success(LockoutSessionDto.fromJson(response));
    } catch (e) {
      logger.error('Failed to get current lockout session', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get current session: $e'),
      );
    }
  }

  /// Gets all friends who are currently locked out.
  ///
  /// Returns sessions with denormalized user profile data.
  FutureResult<List<LockoutSessionDto>> getFriendsLockedOut() async {
    try {
      final response = await supabase.rpc('get_friends_locked_out');

      final sessions = (response as List)
          .map(
            (json) => LockoutSessionDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Result.success(sessions);
    } catch (e) {
      logger.error('Failed to get friends locked out', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get friends locked out: $e'),
      );
    }
  }

  /// Gets a lockout session by ID.
  FutureResult<LockoutSessionDto?> getSessionById(String sessionId) async {
    try {
      final response = await supabase
          .from('lockout_sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (response == null) {
        return Result.success(null);
      }

      return Result.success(LockoutSessionDto.fromJson(response));
    } catch (e) {
      logger.error('Failed to get lockout session by ID', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get session: $e'),
      );
    }
  }

  /// Gets daily lockout stats for a given week (Mon-Sun).
  FutureResult<List<LockoutDailyStatsDto>> getDailyStats({
    required String userId,
    required DateTime weekStart,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_lockout_daily_stats',
        params: {
          'p_user_id': userId,
          'p_week_start':
              '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
        },
      );

      final stats = (response as List)
          .map(
            (json) =>
                LockoutDailyStatsDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Result.success(stats);
    } catch (e) {
      logger.error('Failed to get daily lockout stats', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get daily stats: $e'),
      );
    }
  }

  /// Gets activity stats aggregated by action_text over the rolling 28-day window.
  FutureResult<List<LockoutActivityStatsDto>> getActivityStats({
    required String userId,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_lockout_activity_stats',
        params: {'p_user_id': userId},
      );

      final stats = (response as List)
          .map(
            (json) =>
                LockoutActivityStatsDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Result.success(stats);
    } catch (e) {
      logger.error('Failed to get lockout activity stats', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get activity stats: $e'),
      );
    }
  }

  /// Called when a timed lockout timer reaches 0:00.
  ///
  /// Sets `completed_at = NOW()` on the session row.
  FutureResult<void> completeTimedLockout(String sessionId) async {
    try {
      await supabase.rpc(
        'complete_timed_lockout',
        params: {'p_session_id': sessionId},
      );
      return Result.success(null);
    } catch (e) {
      logger.error('Failed to complete timed lockout', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to complete timed lockout: $e'),
      );
    }
  }

  /// Called when venue lockout leader taps out (NFC scan to exit).
  ///
  /// Sets `completed_at` and sends push notifications to all participants.
  FutureResult<void> leaderCompleteVenueLockout(String sessionId) async {
    try {
      await supabase.rpc(
        'leader_complete_venue_lockout',
        params: {'p_session_id': sessionId},
      );
      return Result.success(null);
    } catch (e) {
      logger.error('Failed to complete venue lockout', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to complete venue lockout: $e'),
      );
    }
  }

  /// Called when a joiner leaves a venue lockout early (taps out before leader).
  FutureResult<void> leaveVenueLockout(String sessionId) async {
    try {
      await supabase.rpc(
        'leave_venue_lockout',
        params: {'p_session_id': sessionId},
      );
      return Result.success(null);
    } catch (e) {
      logger.error('Failed to leave venue lockout', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to leave venue lockout: $e'),
      );
    }
  }

  /// Checks if a lockout session is still active (not completed or deleted).
  ///
  /// Called on app resume to handle leader-ended-all or auto-delete scenarios.
  /// Returns `true` if the session exists and has no `completed_at` value.
  Future<bool> isSessionStillActive(String sessionId) async {
    try {
      final response = await supabase
          .from('lockout_sessions')
          .select('completed_at')
          .eq('id', sessionId)
          .maybeSingle();
      if (response == null) {
        return false; // Session deleted
      }
      return response['completed_at'] == null; // NULL = still active
    } catch (e) {
      logger.warning('Failed to check session active status: $e');
      return true; // Assume active on error (don't break the lockout)
    }
  }

  /// Gets monthly lockout summary for a given year/month.
  FutureResult<LockoutMonthlySummaryDto?> getMonthlySummary({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_lockout_monthly_summary',
        params: {'p_user_id': userId, 'p_year': year, 'p_month': month},
      );

      final rows = response as List;
      if (rows.isEmpty) return Result.success(null);

      return Result.success(
        LockoutMonthlySummaryDto.fromJson(rows.first as Map<String, dynamic>),
      );
    } catch (e) {
      logger.error('Failed to get monthly lockout summary', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get monthly summary: $e'),
      );
    }
  }
}
