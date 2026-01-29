import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetAggregatedNotificationsUseCase
    implements UseCaseContract<Result<List<AggregatedNotificationModel>>> {
  const GetAggregatedNotificationsUseCase({
    required this.repository,
    required this.userId,
    this.pageSize = 20,
    this.cursor,
  });

  final NotificationRepositoryContract repository;
  final String userId;
  final int pageSize;
  final DateTime? cursor;

  @override
  Future<Result<List<AggregatedNotificationModel>>> execute() async {
    return await repository.getAggregatedNotifications(
      userId: userId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}

