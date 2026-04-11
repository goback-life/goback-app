import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class MarkAllNotificationsAsReadUseCase
    implements UseCaseContract<Result<void>> {
  const MarkAllNotificationsAsReadUseCase({
    required this.repository,
    required this.userId,
  });

  final NotificationRepositoryContract repository;
  final String userId;

  @override
  Future<Result<void>> execute() async {
    return await repository.markAllNotificationsAsRead(userId: userId);
  }
}
