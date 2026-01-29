import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class MarkNotificationsAsReadUseCase
    implements UseCaseContract<Result<void>> {
  const MarkNotificationsAsReadUseCase({
    required this.repository,
    required this.userId,
    required this.notificationType,
    this.referenceId,
  });

  final NotificationRepositoryContract repository;
  final String userId;
  final String notificationType;
  final String? referenceId;

  @override
  Future<Result<void>> execute() async {
    return await repository.markNotificationsAsRead(
      userId: userId,
      notificationType: notificationType,
      referenceId: referenceId,
    );
  }
}

