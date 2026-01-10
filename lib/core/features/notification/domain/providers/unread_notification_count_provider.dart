import 'package:cloudless/core/features/notification/data/providers/notification_repository_provider.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/get_unread_notification_count_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_notification_count_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<int>> unreadNotificationCount(
  Ref ref, {
  required String userId,
}) async {
  final useCase = GetUnreadNotificationCountUseCase(
    repository: ref.watch(notificationRepositoryProvider),
    userId: userId,
  );

  return useCase.execute();
}

