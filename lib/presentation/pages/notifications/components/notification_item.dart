import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
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
  });

  final AggregatedNotificationModel notification;
  final VoidCallback onTap;

  Widget _buildPostPreview(
    BuildContext context,
    String? postContentType,
    String? postThumbnailUrl,
    ColorScheme colorScheme,
    NotificationType notificationType,
  ) {
    if (notificationType == NotificationType.friendJoined) {
      return Icon(
        Icons.person_outline,
        color: colorScheme.onSurface.withOpacity(0.5),
        size: 24,
      );
    }

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
    final otherCount = notification.actorCount - 1;

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
      case NotificationType.comment:
        if (otherCount > 0) {
          return translator.translate(
            'pages.notifications.commentMultiple',
            context: context,
            arguments: {
              'username': firstUsername,
              'count': otherCount.toString(),
            },
          );
        }
        return translator.translate(
          'pages.notifications.commentSingle',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.lockoutStarted:
        return translator.translate(
          'pages.notifications.lockoutStarted',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.lockoutJoined:
        return translator.translate(
          'pages.notifications.lockoutJoined',
          context: context,
          arguments: {'username': firstUsername},
        );
      case NotificationType.friendJoined:
        return translator.translate(
          'pages.notifications.friendJoined',
          context: context,
          arguments: {'username': firstUsername},
        );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inHours < 48) return 'Yesterday';
    return DateFormat.MMMd().format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(notificationItemBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: EdgeInsets.all(notificationItemPadding),
        decoration: BoxDecoration(
          color: isUnread
              ? MainColors.accent.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(notificationItemBorderRadius),
          border: Border(
            left: BorderSide(
              color: isUnread
                  ? MainColors.accent
                  : Colors.transparent,
              width: notificationUnreadBorderWidth,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getNotificationText(context, notification),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRelativeTime(notification.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
