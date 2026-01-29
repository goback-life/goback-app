import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';
import 'package:cloudless/core/features/notification/data/services/notification_service_contract.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing notifications.
class NotificationService implements NotificationServiceContract {
  const NotificationService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Gets the notification feed for a user using RPC function.
  /// Returns aggregated notifications with actor info.
  /// Note: The RPC function uses auth.uid() internally - no parameters needed.
  @override
  Future<List<AggregatedNotificationDto>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    DateTime? cursor,
  }) async {
    try {
      // get_notification_feed() uses auth.uid() internally, no parameters needed
      // It returns a maximum of 50 notifications ordered by updated_at DESC
      final response = await supabaseClient.rpc('get_notification_feed');

      if (response == null || response is! List) {
        return [];
      }

      final notifications = <AggregatedNotificationDto>[];
      for (final json in response) {
        final data = json as Map<String, dynamic>;

        // Map database columns to DTO fields
        // DB returns: id, type, reference_id, latest_actor_id, latest_actor_username,
        //             latest_actor_avatar, actor_count, created_at, updated_at, read_at
        notifications.add(AggregatedNotificationDto(
          notificationType: data['type'] as String,
          referenceId: data['reference_id']?.toString(),
          latestActorId: data['latest_actor_id']?.toString(),
          actorIds: data['latest_actor_id'] != null
              ? [data['latest_actor_id'].toString()]
              : [],
          actorUsernames: data['latest_actor_username'] != null
              ? [data['latest_actor_username'] as String]
              : [],
          actorAvatarUrls: data['latest_actor_avatar'] != null
              ? [data['latest_actor_avatar'] as String]
              : null,
          actorCount: data['actor_count'] as int? ?? 1,
          updatedAt: data['updated_at'] as String,
          isRead: data['read_at'] != null,
          postThumbnailUrl: null, // Not returned by this RPC
          postContentType: null, // Not returned by this RPC
        ));
      }

      return notifications;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get notification feed',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Marks a notification group as read.
  /// This marks all notifications with the same type and reference_id as read.
  @override
  Future<void> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? referenceId,
  }) async {
    try {
      var updateQuery = supabaseClient
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('notification_type', notificationType);

      if (referenceId != null) {
        updateQuery = updateQuery.eq('reference_id', referenceId);
      } else {
        // For notifications without reference_id (e.g., friend_joined)
        updateQuery = updateQuery.isFilter('reference_id', null);
      }

      // Execute the update query - await ensures it completes
      await updateQuery;

      logger.info(
        'Notifications marked as read for user $userId, type: $notificationType, referenceId: $referenceId',
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to mark notifications as read',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Marks all notifications as read for a user.
  @override
  Future<void> markAllNotificationsAsRead({required String userId}) async {
    try {
      await supabaseClient
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);

      logger.info('All notifications marked as read for user $userId');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to mark all notifications as read',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Gets the count of unread notifications for a user.
  @override
  Future<int> getUnreadCount({required String userId}) async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .isFilter('read_at', null)
          .count();

      return response.count;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get unread notification count',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Helper method to parse JSONB arrays from PostgreSQL RPC response.
  List<String> _parseJsonbArray(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
