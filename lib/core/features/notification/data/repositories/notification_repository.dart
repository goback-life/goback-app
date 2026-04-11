import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';
import 'package:cloudless/core/features/notification/data/mappers/aggregated_notification_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/notification/data/mappers/notification_exception_mapper.dart';
import 'package:cloudless/core/features/notification/data/services/notification_service_contract.dart';
import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/supabase/data/mixins/supabase_result_processor.dart';
import 'package:dedecube_core/dedecube_core.dart';

class NotificationRepository
    with SupabaseResultProcessor
    implements NotificationRepositoryContract {
  const NotificationRepository({
    required this.notificationService,
    required this.mapper,
  });

  final NotificationServiceContract notificationService;
  final AggregatedNotificationDtoToModelMapper mapper;

  @override
  Future<Result<List<AggregatedNotificationModel>>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    DateTime? cursor,
  }) async {
    return processSupabaseResult<
      List<AggregatedNotificationDto>,
      List<AggregatedNotificationModel>
    >(
      request: () async {
        final dtos = await notificationService.getAggregatedNotifications(
          userId: userId,
          pageSize: pageSize,
          cursor: cursor,
        );
        return Result.success(dtos);
      },
      responseMapper: (dtos) async {
        return mapper.mapDtoList(dtos);
      },
      exceptionMapper: NotificationExceptionMapper.fromSupabaseException,
    );
  }

  @override
  Future<Result<void>> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? referenceId,
  }) async {
    return processSupabaseResult<void, void>(
      request: () async {
        await notificationService.markNotificationsAsRead(
          userId: userId,
          notificationType: notificationType,
          referenceId: referenceId,
        );
        return Result.success(null);
      },
      responseMapper: (_) async {},
      exceptionMapper: NotificationExceptionMapper.fromSupabaseException,
    );
  }

  @override
  Future<Result<void>> markAllNotificationsAsRead({
    required String userId,
  }) async {
    return processSupabaseResult<void, void>(
      request: () async {
        await notificationService.markAllNotificationsAsRead(userId: userId);
        return Result.success(null);
      },
      responseMapper: (_) async {},
      exceptionMapper: NotificationExceptionMapper.fromSupabaseException,
    );
  }

  @override
  Future<Result<int>> getUnreadCount({required String userId}) async {
    return processSupabaseResult<int, int>(
      request: () async {
        final count = await notificationService.getUnreadCount(userId: userId);
        return Result.success(count);
      },
      responseMapper: (count) async => count,
      exceptionMapper: NotificationExceptionMapper.fromSupabaseException,
    );
  }
}
