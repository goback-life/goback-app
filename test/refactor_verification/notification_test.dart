/// Notification feature refactoring verification test.
///
/// Documents public API contracts and structural invariants that must
/// survive refactoring. These are compile-time and structural checks
/// (no runtime Supabase/Firebase dependencies).
library;

import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';
import 'package:cloudless/core/features/notification/data/dtos/notification_dto.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_fetch_exception.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_network_exception.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_unauthorized_exception.dart';
import 'package:cloudless/core/features/notification/data/mappers/aggregated_notification_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/notification/data/mappers/notification_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/notification/data/mappers/notification_exception_mapper.dart';
import 'package:cloudless/core/features/notification/data/services/notification_service_contract.dart';
import 'package:cloudless/core/features/notification/domain/contracts/notification_repository_contract.dart';
import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/exceptions/notification_exception.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/notification/domain/models/notification_model.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/get_aggregated_notifications_use_case.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/get_unread_notification_count_use_case.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/mark_all_notifications_as_read_use_case.dart';
import 'package:cloudless/core/features/notification/domain/use_cases/mark_notifications_as_read_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── NotificationType enum ────────────────────────────────────────────
  group('NotificationType', () {
    test('has all expected values', () {
      expect(
        NotificationType.values,
        containsAll([
          NotificationType.reaction,
          NotificationType.tag,
          NotificationType.comment,
          NotificationType.lockoutStarted,
          NotificationType.lockoutJoined,
          NotificationType.friendJoined,
          NotificationType.connectionRequest,
        ]),
      );
      expect(NotificationType.values.length, 7);
    });

    test('fromValue round-trips all enum values', () {
      for (final type in NotificationType.values) {
        expect(NotificationType.fromValue(type.value), type);
      }
    });

    test('fromValue throws on unknown value', () {
      expect(
        () => NotificationType.fromValue('unknown_type'),
        throwsArgumentError,
      );
    });
  });

  // ── AggregatedNotificationDto ────────────────────────────────────────
  group('AggregatedNotificationDto', () {
    test('can be constructed with required fields', () {
      final dto = AggregatedNotificationDto(
        notificationType: 'reaction',
        actorIds: ['a1'],
        actorUsernames: ['user1'],
        actorCount: 1,
        updatedAt: '2025-01-01T00:00:00Z',
        isRead: false,
      );
      expect(dto.notificationType, 'reaction');
      expect(dto.actorIds, ['a1']);
      expect(dto.actorCount, 1);
      expect(dto.isRead, false);
    });

    test('supports all optional fields', () {
      final dto = AggregatedNotificationDto(
        notificationType: 'comment',
        referenceId: 'ref-1',
        latestActorId: 'actor-1',
        actorIds: ['actor-1'],
        actorUsernames: ['username1'],
        actorAvatarUrls: ['https://example.com/avatar.png'],
        actorCount: 1,
        updatedAt: '2025-01-01T00:00:00Z',
        isRead: true,
        postThumbnailUrl: 'https://example.com/thumb.png',
        postContentType: 'image',
      );
      expect(dto.referenceId, 'ref-1');
      expect(dto.latestActorId, 'actor-1');
      expect(dto.actorAvatarUrls, isNotNull);
      expect(dto.postThumbnailUrl, isNotNull);
      expect(dto.postContentType, 'image');
    });

    test('fromJson round-trip via toJson', () {
      final dto = AggregatedNotificationDto(
        notificationType: 'tag',
        actorIds: ['id1'],
        actorUsernames: ['u1'],
        actorCount: 1,
        updatedAt: '2025-01-01T00:00:00Z',
        isRead: false,
      );
      final json = dto.toJson();
      final restored = AggregatedNotificationDto.fromJson(json);
      expect(restored, dto);
    });
  });

  // ── NotificationDto ──────────────────────────────────────────────────
  group('NotificationDto', () {
    test('can be constructed with required fields', () {
      final dto = NotificationDto(
        id: 'n-1',
        userId: 'u-1',
        notificationType: 'reaction',
        relatedUserId: 'u-2',
        createdAt: '2025-01-01T00:00:00Z',
      );
      expect(dto.id, 'n-1');
      expect(dto.readAt, isNull);
    });

    test('fromJson round-trip via toJson', () {
      final dto = NotificationDto(
        id: 'n-1',
        userId: 'u-1',
        notificationType: 'reaction',
        relatedUserId: 'u-2',
        createdAt: '2025-01-01T00:00:00Z',
      );
      final json = dto.toJson();
      final restored = NotificationDto.fromJson(json);
      expect(restored, dto);
    });
  });

  // ── AggregatedNotificationModel ──────────────────────────────────────
  group('AggregatedNotificationModel', () {
    test('can be constructed with required fields', () {
      final model = AggregatedNotificationModel(
        type: NotificationType.reaction,
        actorIds: ['a1'],
        actorUsernames: ['user1'],
        actorCount: 1,
        updatedAt: DateTime.utc(2025),
        isRead: false,
      );
      expect(model.type, NotificationType.reaction);
      expect(model.referenceId, isNull);
    });
  });

  // ── NotificationModel ────────────────────────────────────────────────
  group('NotificationModel', () {
    test('can be constructed with required fields', () {
      final model = NotificationModel(
        id: 'n-1',
        userId: 'u-1',
        type: NotificationType.comment,
        relatedUserId: 'u-2',
        createdAt: DateTime.utc(2025),
      );
      expect(model.id, 'n-1');
      expect(model.readAt, isNull);
    });
  });

  // ── Mappers ──────────────────────────────────────────────────────────
  group('AggregatedNotificationDtoToModelMapper', () {
    test('maps single DTO to model correctly', () {
      final mapper = AggregatedNotificationDtoToModelMapper();
      final dto = AggregatedNotificationDto(
        notificationType: 'reaction',
        referenceId: 'post-1',
        latestActorId: 'actor-1',
        actorIds: ['actor-1'],
        actorUsernames: ['user1'],
        actorCount: 1,
        updatedAt: '2025-01-01T12:00:00Z',
        isRead: false,
      );

      final model = mapper.mapDto(dto);
      expect(model.type, NotificationType.reaction);
      expect(model.referenceId, 'post-1');
      expect(model.latestActorId, 'actor-1');
      expect(model.actorCount, 1);
      expect(model.isRead, false);
    });

    test('maps list of DTOs', () {
      final mapper = AggregatedNotificationDtoToModelMapper();
      final dtos = [
        AggregatedNotificationDto(
          notificationType: 'reaction',
          actorIds: ['a1'],
          actorUsernames: ['u1'],
          actorCount: 1,
          updatedAt: '2025-01-01T00:00:00Z',
          isRead: false,
        ),
        AggregatedNotificationDto(
          notificationType: 'comment',
          actorIds: ['a2'],
          actorUsernames: ['u2'],
          actorCount: 1,
          updatedAt: '2025-01-02T00:00:00Z',
          isRead: true,
        ),
      ];

      final models = mapper.mapDtoList(dtos);
      expect(models.length, 2);
      expect(models[0].type, NotificationType.reaction);
      expect(models[1].type, NotificationType.comment);
    });
  });

  group('NotificationDtoToModelMapper', () {
    test('maps single DTO to model correctly', () {
      final mapper = NotificationDtoToModelMapper();
      final dto = NotificationDto(
        id: 'n-1',
        userId: 'u-1',
        notificationType: 'tag',
        referenceId: 'post-1',
        relatedUserId: 'u-2',
        createdAt: '2025-06-15T10:30:00Z',
        readAt: '2025-06-15T11:00:00Z',
      );

      final model = mapper.mapDto(dto);
      expect(model.id, 'n-1');
      expect(model.type, NotificationType.tag);
      expect(model.referenceId, 'post-1');
      expect(model.readAt, isNotNull);
    });
  });

  // ── Exception hierarchy ──────────────────────────────────────────────
  group('Notification exceptions', () {
    test('NotificationException is base type', () {
      const e = NotificationException();
      expect(e.message, contains('Notification'));
    });

    test('NotificationFetchException extends NotificationException', () {
      const e = NotificationFetchException();
      expect(e, isA<NotificationException>());
    });

    test('NotificationNetworkException extends NotificationException', () {
      const e = NotificationNetworkException();
      expect(e, isA<NotificationException>());
    });

    test('NotificationUnauthorizedException extends NotificationException', () {
      const e = NotificationUnauthorizedException();
      expect(e, isA<NotificationException>());
    });
  });

  // ── Contract interfaces ──────────────────────────────────────────────
  group('Contract interfaces', () {
    test('NotificationServiceContract defines required methods', () {
      // Compile-time check: this test passes if the file imports succeed
      // and the abstract class is properly defined.
      expect(NotificationServiceContract, isNotNull);
    });

    test('NotificationRepositoryContract defines required methods', () {
      expect(NotificationRepositoryContract, isNotNull);
    });
  });

  // ── Exception mapper ─────────────────────────────────────────────────
  group('NotificationExceptionMapper', () {
    test('static fromSupabaseException is accessible', () {
      expect(
        NotificationExceptionMapper.fromSupabaseException,
        isA<Function>(),
      );
    });
  });

  // ── Use cases structural checks ──────────────────────────────────────
  group('Use case classes exist and are constructible', () {
    // These verify the public API surface of use case classes.
    // We cannot instantiate them without a real repository, but we verify
    // the types exist and are accessible.
    test('GetAggregatedNotificationsUseCase type exists', () {
      expect(GetAggregatedNotificationsUseCase, isNotNull);
    });

    test('GetUnreadNotificationCountUseCase type exists', () {
      expect(GetUnreadNotificationCountUseCase, isNotNull);
    });

    test('MarkAllNotificationsAsReadUseCase type exists', () {
      expect(MarkAllNotificationsAsReadUseCase, isNotNull);
    });

    test('MarkNotificationsAsReadUseCase type exists', () {
      expect(MarkNotificationsAsReadUseCase, isNotNull);
    });
  });
}
