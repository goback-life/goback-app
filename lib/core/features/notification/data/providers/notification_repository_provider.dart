import 'package:cloudless/core/features/notification/data/mappers/aggregated_notification_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/notification/data/providers/notification_service_provider.dart';
import 'package:cloudless/core/features/notification/data/repositories/notification_repository.dart';
import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_repository_provider.g.dart';

@Riverpod(keepAlive: false)
NotificationRepositoryContract notificationRepository(Ref ref) {
  return NotificationRepository(
    notificationService: ref.watch(notificationServiceProvider),
    mapper: AggregatedNotificationDtoToModelMapper(),
  );
}

