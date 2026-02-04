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
      await supabase.rpc(
        'join_lockout_session',
        params: {'p_session_id': sessionId},
      );

      return Result.success(null);
    } catch (e) {
      logger.error('Failed to join lockout session', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to join lockout session: $e'),
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
      // ignore: avoid_print
      print('[SERVICE] getFriendsLockedOut: Calling RPC...');
      final response = await supabase.rpc('get_friends_locked_out');
      // ignore: avoid_print
      print('[SERVICE] getFriendsLockedOut: Raw response: $response');

      final sessions = (response as List)
          .map((json) {
            // ignore: avoid_print
            print('[SERVICE] Parsing session: $json');
            return LockoutSessionDto.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      // ignore: avoid_print
      print('[SERVICE] Parsed ${sessions.length} sessions');
      return Result.success(sessions);
    } catch (e) {
      // ignore: avoid_print
      print('[SERVICE] ERROR: $e');
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
}
