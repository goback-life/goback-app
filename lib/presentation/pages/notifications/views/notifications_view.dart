import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/notification/data/providers/notification_repository_provider.dart';
import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/hooks/use_aggregated_notifications.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/notification/domain/providers/aggregated_notifications_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/mark_all_notifications_as_read_use_case.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/notifications/components/notification_empty_state.dart';
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
            );

            // Check if circle is full to disable Accept on connection requests
            final circleMembersAsync = ref.watch(getCircleMembersProvider);
            final circleCount =
                circleMembersAsync.whenOrNull(
                  data: (result) =>
                      result.fold((members) => members.length, (_) => 0),
                ) ??
                0;
            final isCircleFull = circleCount >= 150;

            // Auto-mark all as read after 1.5s delay
            useEffect(() {
              final timer = Timer(
                const Duration(milliseconds: 1500),
                () => _markAllAsReadSilently(ref, user.id),
              );
              return timer.cancel;
            }, []);

            return notificationsHook.notifications.when(
              data: (notificationsResult) {
                return notificationsResult.fold(
                  (notifications) {
                    final filtered = notifications
                        .where(
                          (n) =>
                              n.type != NotificationType.lockoutStarted &&
                              n.type != NotificationType.lockoutJoined,
                        )
                        .toList();

                    if (filtered.isEmpty) {
                      return const NotificationEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await notificationsHook.refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final notification = filtered[index];
                          return NotificationItem(
                            key: ValueKey(
                              'notification_${notification.type.value}_${notification.referenceId ?? 'null'}_${notification.updatedAt.millisecondsSinceEpoch}',
                            ),
                            notification: notification,
                            onTap: () async {
                              await _navigateFromNotification(
                                context,
                                ref,
                                notification,
                              );
                            },
                            onAccept:
                                notification.type ==
                                        NotificationType.connectionRequest &&
                                    !isCircleFull
                                ? () => _respondToRequest(
                                    ref,
                                    notification,
                                    user.id,
                                    accept: true,
                                  )
                                : null,
                            onDeny:
                                notification.type ==
                                    NotificationType.connectionRequest
                                ? () => _respondToRequest(
                                    ref,
                                    notification,
                                    user.id,
                                    accept: false,
                                  )
                                : null,
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

  /// Silently mark all notifications as read and clear the badge.
  void _markAllAsReadSilently(WidgetRef ref, String userId) {
    // Optimistically clear the badge immediately
    ref.invalidate(unreadNotificationCountProvider(userId: userId));

    // Fire-and-forget the API call
    final useCase = MarkAllNotificationsAsReadUseCase(
      repository: ref.read(notificationRepositoryProvider),
      userId: userId,
    );

    useCase.execute().then((result) {
      result.fold(
        (_) {
          // Refresh notifications so read_at updates in UI
          ref.invalidate(
            aggregatedNotificationsProvider(userId: userId, pageSize: 20),
          );
        },
        (error) {
          logger.error(
            'Failed to mark notifications as read',
            exception: error,
          );
        },
      );
    });
  }

  void _respondToRequest(
    WidgetRef ref,
    AggregatedNotificationModel notification,
    String userId, {
    required bool accept,
  }) {
    if (notification.referenceId == null) return;
    ref
        .read(
          respondToConnectionRequestProvider(
            notification.referenceId!,
            accept: accept,
          ).future,
        )
        .then((result) {
          result.fold(
            (_) {
              // Refresh notifications + circle members on accept
              ref.invalidate(
                aggregatedNotificationsProvider(userId: userId, pageSize: 20),
              );
              if (accept) {
                ref.invalidate(getCircleMembersProvider);
              }
            },
            (error) {
              logger.error('Failed to respond to request', exception: error);
            },
          );
        });
  }

  Future<void> _navigateFromNotification(
    BuildContext context,
    WidgetRef ref,
    AggregatedNotificationModel notification,
  ) async {
    if (!context.mounted) return;

    switch (notification.type) {
      case NotificationType.lockoutStarted:
      case NotificationType.lockoutJoined:
      case NotificationType.memberJoined:
        break;
      case NotificationType.reaction:
      case NotificationType.tag:
      case NotificationType.comment:
        if (notification.referenceId != null) {
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
                      postId: notification.referenceId!,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      case NotificationType.connectionRequest:
        // Tap navigates to the sender's profile
        if (notification.actorIds.isNotEmpty) {
          final actorId = notification.actorIds.first;
          router.push(ExternalProfileRoutable(userId: actorId));
        }
      case NotificationType.friendJoined:
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
                (error) => false,
              );

              if (isConnected) {
                router.push(CircleProfileRoutable(userId: actorId));
              } else {
                router.push(ExternalProfileRoutable(userId: actorId));
              }
            }
          }
        }
    }
  }
}
