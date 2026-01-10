import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/notification/data/providers/notification_repository_provider.dart';
import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/hooks/use_aggregated_notifications.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/notification/domain/providers/aggregated_notifications_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/mark_all_notifications_as_read_use_case.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/mark_notifications_as_read_use_case.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/notifications/components/notification_empty_state.dart';
import 'package:cloudless/presentation/pages/notifications/components/notification_header.dart';
import 'package:cloudless/presentation/pages/notifications/components/notification_item.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class NotificationsView extends HookConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return currentUserAsync.when(
      data: (userResult) {
        return userResult.fold(
          (user) {
            final notificationsHook = useAggregatedNotifications(
              ref,
              userId: user.id,
              pageSize: 20,
              pageOffset: 0,
            );

            return notificationsHook.notifications.when(
              data: (notificationsResult) {
                return notificationsResult.fold(
                  (notifications) {
                    if (notifications.isEmpty) {
                      return const NotificationEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await notificationsHook.refresh();
                        // Also refresh unread count when pulling to refresh
                        ref.invalidate(
                          unreadNotificationCountProvider(userId: user.id),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: notifications.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return NotificationHeader(
                              onMarkAllAsRead: () async {
                                await _handleMarkAllAsRead(ref, user.id);
                              },
                            );
                          }
                          final notification = notifications[index - 1];
                          return NotificationItem(
                            key: ValueKey('notification_${notification.type.value}_${notification.relatedPostId ?? 'null'}_${notification.latestCreatedAt.millisecondsSinceEpoch}'),
                            itemKey: 'notification_${notification.type.value}_${notification.relatedPostId ?? 'null'}_${notification.latestCreatedAt.millisecondsSinceEpoch}',
                            notification: notification,
                            onTap: () async {
                              await _handleNotificationTap(
                                context,
                                ref,
                                user.id,
                                notification,
                              );
                            },
                            onSwipeToMarkRead: () async {
                              await _handleSwipeToMarkRead(
                                ref,
                                user.id,
                                notification,
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                  (error) => Center(
                    child: Text(
                      'Error loading notifications: ${error.toString()}',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          },
          (error) => Center(
            child: Text(
              'Error loading user: ${error.toString()}',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error: ${error.toString()}',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AggregatedNotificationModel notification,
  ) async {
    // Mark notification as read if unread
    if (!notification.isRead) {
      await _handleSwipeToMarkRead(ref, userId, notification);
    }

    // Navigate to related post/profile based on notification type
    await _navigateFromNotification(context, ref, notification);
  }

  Future<void> _handleSwipeToMarkRead(
    WidgetRef ref,
    String userId,
    AggregatedNotificationModel notification,
  ) async {
    // Mark notification as read
    final useCase = MarkNotificationsAsReadUseCase(
      repository: ref.read(notificationRepositoryProvider),
      userId: userId,
      notificationType: notification.type.value,
      relatedPostId: notification.relatedPostId,
    );

    final result = await useCase.execute();

    result.fold(
      (_) {
        // Invalidate providers to refresh UI
        ref.invalidate(
          aggregatedNotificationsProvider(
            userId: userId,
            pageSize: 20,
            pageOffset: 0,
          ),
        );
        ref.invalidate(
          unreadNotificationCountProvider(userId: userId),
        );
        logger.info(
          'Notification marked as read: ${notification.type.value}, postId: ${notification.relatedPostId}',
        );
      },
      (error) {
        logger.error(
          'Failed to mark notification as read',
          exception: error,
        );
      },
    );
  }

  Future<void> _navigateFromNotification(
    BuildContext context,
    WidgetRef ref,
    AggregatedNotificationModel notification,
  ) async {
    if (!context.mounted) return;

    switch (notification.type) {
      case NotificationType.reaction:
      case NotificationType.tag:
      case NotificationType.reply:
        // Navigate to the related post
        if (notification.relatedPostId != null) {
          await showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            builder: (sheetContext) => GestureDetector(
              onTap: () => Navigator.of(sheetContext).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 12.0,
                      right: 12.0,
                      top: 150.0,
                      bottom: 20.0,
                    ),
                    child: PostDetailPage.byId(
                      postId: notification.relatedPostId!,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        break;
      case NotificationType.circleJoin:
        // Navigate to the actor's profile (first actor who joined)
        if (notification.actorIds.isNotEmpty) {
          final actorId = notification.actorIds.first;

          final currentUserAsync = ref.read(getCurrentUserProvider);
          final currentUserId = currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (_) => null),
          );

          if (currentUserId != null) {
            if (actorId == currentUserId) {
              router.push(const ProfileRoutable());
            } else {
              final connectionResult = await ref.read(
                isUserConnectedProvider(actorId).future,
              );
              final isConnected = connectionResult.fold(
                (isConnected) => isConnected,
                (error) {
                  logger.error(
                    'Failed to check user connection',
                    exception: error,
                  );
                  return false;
                },
              );

              if (isConnected) {
                router.push(CircleProfileRoutable(userId: actorId));
              } else {
                router.push(ExternalProfileRoutable(userId: actorId));
              }
            }
          }
        }
        break;
    }
  }

  Future<void> _handleMarkAllAsRead(
    WidgetRef ref,
    String userId,
  ) async {
    final useCase = MarkAllNotificationsAsReadUseCase(
      repository: ref.read(notificationRepositoryProvider),
      userId: userId,
    );

    final result = await useCase.execute();

    result.fold(
      (_) {
        // Invalidate providers to refresh UI
        ref.invalidate(
          aggregatedNotificationsProvider(
            userId: userId,
            pageSize: 20,
            pageOffset: 0,
          ),
        );
        ref.invalidate(
          unreadNotificationCountProvider(userId: userId),
        );
        logger.info('All notifications marked as read for user: $userId');
      },
      (error) {
        logger.error(
          'Failed to mark all notifications as read',
          exception: error,
        );
      },
    );
  }
}

