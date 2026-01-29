import 'package:cloudless/core/features/notification/data/providers/notification_repository_provider.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/get_aggregated_notifications_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'aggregated_notifications_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<AggregatedNotificationModel>>> aggregatedNotifications(
  Ref ref, {
  required String userId,
  int pageSize = 20,
  DateTime? cursor,
}) async {
  final useCase = GetAggregatedNotificationsUseCase(
    repository: ref.watch(notificationRepositoryProvider),
    userId: userId,
    pageSize: pageSize,
    cursor: cursor,
  );

  return useCase.execute();
}

