import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetUnreadNotificationCountUseCase
    implements UseCaseContract<Result<int>> {
  const GetUnreadNotificationCountUseCase({
    required this.repository,
    required this.userId,
  });

  final NotificationRepositoryContract repository;
  final String userId;

  @override
  Future<Result<int>> execute() async {
    return await repository.getUnreadCount(userId: userId);
  }
}

