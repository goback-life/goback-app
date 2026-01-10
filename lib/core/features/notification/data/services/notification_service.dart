import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';
import 'package:cloudless/core/features/notification/data/services/notification_service_contract.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing notifications.
class NotificationService implements NotificationServiceContract {
  const NotificationService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Gets aggregated notifications for a user using RPC function.
  /// Follows the same pattern as get_user_feed.
  @override
  Future<List<AggregatedNotificationDto>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    int pageOffset = 0,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_aggregated_notifications',
        params: {
          'p_user_id': userId,
          'page_size': pageSize,
          'page_offset': pageOffset,
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      final notifications = <AggregatedNotificationDto>[];
      for (final json in response) {
        final data = json as Map<String, dynamic>;
        // Convert JSONB arrays to List<String>
        final actorIds = _parseJsonbArray(data['actor_ids']);
        final actorUsernames = _parseJsonbArray(data['actor_usernames']);
        final actorAvatarUrls = data['actor_avatar_urls'] != null
            ? _parseJsonbArray(data['actor_avatar_urls'])
            : null;

        notifications.add(AggregatedNotificationDto(
          notificationType: data['notification_type'] as String,
          relatedPostId: data['related_post_id'] as String?,
          actorIds: actorIds,
          actorUsernames: actorUsernames,
          actorAvatarUrls: actorAvatarUrls,
          count: data['count'] as int,
          latestCreatedAt: data['latest_created_at'] as String,
          isRead: data['is_read'] as bool,
          postThumbnailUrl: data['post_thumbnail_url'] as String?,
          postContentType: data['post_content_type'] as String?,
        ));
      }

      return notifications;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get aggregated notifications',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Marks a notification group as read.
  /// This marks all notifications with the same type and related_post_id as read.
  @override
  Future<void> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? relatedPostId,
  }) async {
    try {
      var updateQuery = supabaseClient
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('notification_type', notificationType);

      if (relatedPostId != null) {
        updateQuery = updateQuery.eq('related_post_id', relatedPostId);
      } else {
        // For notifications without related_post_id (e.g., circle_join)
        updateQuery = updateQuery.isFilter('related_post_id', null);
      }

      // Execute the update query - await ensures it completes
      await updateQuery;

      logger.info(
        'Notifications marked as read for user $userId, type: $notificationType, postId: $relatedPostId',
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
