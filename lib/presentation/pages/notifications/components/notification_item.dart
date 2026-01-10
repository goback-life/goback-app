import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem extends HookConsumerWidget
    with MainLayout, NotificationsLayout {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onSwipeToMarkRead,
    required this.itemKey,
  });

  final AggregatedNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onSwipeToMarkRead;
  final String itemKey;

  Widget _buildPostPreview(
    BuildContext context,
    String? postContentType,
    String? postThumbnailUrl,
    ColorScheme colorScheme,
    NotificationType notificationType,
  ) {
    // For circle_join notifications (no related post), show person icon
    if (notificationType == NotificationType.circleJoin) {
      return Icon(
        Icons.person_outline,
        color: colorScheme.onSurface.withOpacity(0.5),
        size: 24,
      );
    }

    // Show "T" for text posts
    if (postContentType == 'text') {
      return Center(
        child: Text(
          'T',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      );
    }

    // Show thumbnail for posts with media
    if (postThumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          postThumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_outlined,
            color: colorScheme.onSurface.withOpacity(0.5),
            size: 24,
          ),
        ),
      );
    }

    // Default icon for posts without thumbnail (fallback)
    return Icon(
      Icons.image_outlined,
      color: colorScheme.onSurface.withOpacity(0.5),
      size: 24,
    );
  }

  String _getNotificationText(
    BuildContext context,
    AggregatedNotificationModel notification,
  ) {
    final usernames = notification.actorUsernames;
    if (usernames.isEmpty) return '';

    final firstUsername = usernames.first;
    final otherCount = notification.count - 1;

    switch (notification.type) {
      case NotificationType.reaction:
        if (otherCount > 0) {
          return translator.translate(
            'pages.notifications.reactionMultiple',
            context: context,
            arguments: {
              'username': firstUsername,
              'count': otherCount.toString(),
            },
          );
        }
        return translator.translate(
          'pages.notifications.reactionSingle',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.tag:
        return translator.translate(
          'pages.notifications.tag',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.reply:
        if (otherCount > 0) {
          return translator.translate(
            'pages.notifications.replyMultiple',
            context: context,
            arguments: {
              'username': firstUsername,
              'count': otherCount.toString(),
            },
          );
        }
        return translator.translate(
          'pages.notifications.replySingle',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.circleJoin:
        return translator.translate(
          'pages.notifications.circleJoin',
          context: context,
          arguments: {'username': firstUsername},
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Only allow swipe if notification is unread
    if (!notification.isRead) {
      return Dismissible(
        key: Key(itemKey),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(notificationItemBorderRadius),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(
            Icons.check_circle_outline,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          // Mark as read but don't actually dismiss the item
          // The item will update to read state after refresh
          onSwipeToMarkRead();
          return false; // Prevent automatic removal
        },
        child: _buildNotificationContent(context, theme, colorScheme),
      );
    }

    return _buildNotificationContent(context, theme, colorScheme);
  }

  Widget _buildNotificationContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(notificationItemBorderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: EdgeInsets.all(notificationItemPadding),
        decoration: BoxDecoration(
          color: notification.isRead
              ? colorScheme.surface
              : colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(notificationItemBorderRadius),
          border: Border.all(
            color: notification.isRead
                ? colorScheme.outline.withOpacity(0.1)
                : colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post thumbnail or text indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: _buildPostPreview(
                context,
                notification.postContentType,
                notification.postThumbnailUrl,
                colorScheme,
                notification.type,
              ),
            ),
            const SizedBox(width: 12),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getNotificationText(context, notification),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(
                          notification.latestCreatedAt,
                        ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

