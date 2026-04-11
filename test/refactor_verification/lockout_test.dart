import 'package:cloudless/core/features/lockout/data/dtos/lockout_activity_stats_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_monthly_summary_dto.dart';
import 'package:cloudless/core/features/lockout/data/dtos/lockout_session_dto.dart';
import 'package:cloudless/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/lockout/domain/models/manual_lockout_model.dart';
import 'package:cloudless/core/features/lockout/domain/utilities/goback_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verification tests for lockout feature refactoring.
///
/// These tests cover pure logic that can be tested without Supabase, storage,
/// or Riverpod container setup. They document the public API contracts that
/// must remain unchanged after refactoring.
void main() {
  group('GobackScoreCalculator', () {
    test('returns null for duration <= 60 seconds', () {
      expect(
        GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 70,
          duration: const Duration(seconds: 60),
        ),
        isNull,
      );
      expect(
        GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 70,
          duration: const Duration(seconds: 30),
        ),
        isNull,
      );
    });

    test('returns non-null for duration > 60 seconds', () {
      expect(
        GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 70,
          duration: const Duration(minutes: 2),
        ),
        isNotNull,
      );
    });

    test('higher score for less battery drain', () {
      final lowDrain = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 78, // 2% drain
        duration: const Duration(hours: 2),
      );
      final highDrain = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 50, // 30% drain
        duration: const Duration(hours: 2),
      );
      expect(lowDrain, greaterThan(highDrain!));
    });

    test('time multiplier increases score for longer lockouts', () {
      // Same battery drain rate but different durations
      final short = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 79,
        duration: const Duration(minutes: 10),
      );
      final long = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 76,
        duration: const Duration(hours: 4),
      );
      // Long lockout gets full 1.0x multiplier vs ~0.71x for short
      expect(long, greaterThan(short!));
    });

    test('caps time multiplier at 4 hours', () {
      final fourHours = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 72,
        duration: const Duration(hours: 4),
      );
      final eightHours = GobackScoreCalculator.calculate(
        batteryStart: 80,
        batteryEnd: 64,
        duration: const Duration(hours: 8),
      );
      // Same drain/hr, so same score - multiplier capped at 4hr
      expect(fourHours, equals(eightHours));
    });

    test('falls back to time-only score capped at 70 when battery is null', () {
      final score = GobackScoreCalculator.calculate(
        batteryStart: null,
        batteryEnd: null,
        duration: const Duration(hours: 4),
      );
      expect(score, isNotNull);
      expect(score, lessThanOrEqualTo(70));
    });

    test('treats negative battery drain (charging) as 0 drain', () {
      final score = GobackScoreCalculator.calculate(
        batteryStart: 50,
        batteryEnd: 80, // Charged during lockout
        duration: const Duration(hours: 2),
      );
      expect(score, isNotNull);
      // 0 drain = perfect battery quality
      expect(score, greaterThan(80));
    });

    test('score is always between 0 and 100', () {
      // Test a variety of inputs
      final testCases = [
        (start: 100, end: 0, dur: const Duration(hours: 1)), // Max drain
        (
          start: 50,
          end: 50,
          dur: const Duration(minutes: 2),
        ), // No drain, short
        (start: 80, end: 78, dur: const Duration(hours: 4)), // Low drain, long
        (start: 90, end: 10, dur: const Duration(hours: 4)), // High drain, long
      ];

      for (final tc in testCases) {
        final score = GobackScoreCalculator.calculate(
          batteryStart: tc.start,
          batteryEnd: tc.end,
          duration: tc.dur,
        );
        if (score != null) {
          expect(
            score,
            greaterThanOrEqualTo(0),
            reason: 'Score $score < 0 for $tc',
          );
          expect(
            score,
            lessThanOrEqualTo(100),
            reason: 'Score $score > 100 for $tc',
          );
        }
      }
    });
  });

  group('LockoutSessionDtoToModelMapper', () {
    late LockoutSessionDtoToModelMapper mapper;

    setUp(() {
      mapper = LockoutSessionDtoToModelMapper();
    });

    test('maps all fields from DTO to model', () {
      final dto = LockoutSessionDto(
        id: 'session-1',
        userId: 'user-1',
        startedAt: '2024-01-01T10:00:00.000Z',
        endsAt: '2024-01-01T14:00:00.000Z',
        actionText: 'Going hiking',
        locationLat: 51.5074,
        locationLng: -0.1278,
        locationName: 'London',
        postId: 'post-1',
        createdAt: '2024-01-01T09:55:00.000Z',
        participants: ['user-2', 'user-3'],
        username: 'testuser',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final model = mapper.mapDto(dto);

      expect(model.id, equals('session-1'));
      expect(model.userId, equals('user-1'));
      expect(
        model.startedAt,
        equals(DateTime.parse('2024-01-01T10:00:00.000Z')),
      );
      expect(model.endsAt, equals(DateTime.parse('2024-01-01T14:00:00.000Z')));
      expect(model.actionText, equals('Going hiking'));
      expect(model.locationLat, equals(51.5074));
      expect(model.locationLng, equals(-0.1278));
      expect(model.locationName, equals('London'));
      expect(model.postId, equals('post-1'));
      expect(
        model.createdAt,
        equals(DateTime.parse('2024-01-01T09:55:00.000Z')),
      );
      expect(model.participants, equals(['user-2', 'user-3']));
      expect(model.username, equals('testuser'));
      expect(model.avatarUrl, equals('https://example.com/avatar.jpg'));
    });

    test('falls back createdAt to startedAt when createdAt is null', () {
      final dto = LockoutSessionDto(
        id: 'session-1',
        userId: 'user-1',
        startedAt: '2024-01-01T10:00:00.000Z',
        endsAt: '2024-01-01T14:00:00.000Z',
        createdAt: null,
      );

      final model = mapper.mapDto(dto);

      expect(
        model.createdAt,
        equals(DateTime.parse('2024-01-01T10:00:00.000Z')),
      );
    });

    test('maps list of DTOs', () {
      final dtos = [
        LockoutSessionDto(
          id: 'session-1',
          userId: 'user-1',
          startedAt: '2024-01-01T10:00:00.000Z',
          endsAt: '2024-01-01T14:00:00.000Z',
        ),
        LockoutSessionDto(
          id: 'session-2',
          userId: 'user-2',
          startedAt: '2024-01-02T10:00:00.000Z',
          endsAt: '2024-01-02T14:00:00.000Z',
        ),
      ];

      final models = mapper.mapDtoList(dtos);

      expect(models.length, equals(2));
      expect(models[0].id, equals('session-1'));
      expect(models[1].id, equals('session-2'));
    });

    test('handles nullable fields as null', () {
      final dto = LockoutSessionDto(
        id: 'session-1',
        userId: 'user-1',
        startedAt: '2024-01-01T10:00:00.000Z',
        endsAt: '2024-01-01T14:00:00.000Z',
      );

      final model = mapper.mapDto(dto);

      expect(model.actionText, isNull);
      expect(model.locationLat, isNull);
      expect(model.locationLng, isNull);
      expect(model.locationName, isNull);
      expect(model.postId, isNull);
      expect(model.username, isNull);
      expect(model.avatarUrl, isNull);
    });
  });

  group('ManualLockoutModel', () {
    test('constructs with required fields', () {
      const model = ManualLockoutModel(isLockedOut: true);
      expect(model.isLockedOut, isTrue);
      expect(model.remainingDuration, isNull);
      expect(model.isCompletionPending, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const model = ManualLockoutModel(
        isLockedOut: true,
        remainingDuration: Duration(hours: 2),
        isCompletionPending: true,
      );

      final copied = model.copyWith(isLockedOut: false);
      expect(copied.isLockedOut, isFalse);
      expect(copied.remainingDuration, equals(const Duration(hours: 2)));
      expect(copied.isCompletionPending, isTrue);
    });
  });

  group('LockoutSessionDto JSON', () {
    test('reads id from lockout_id key (RPC response)', () {
      final dto = LockoutSessionDto.fromJson({
        'lockout_id': 'rpc-id-123',
        'user_id': 'user-1',
        'started_at': '2024-01-01T10:00:00.000Z',
        'ends_at': '2024-01-01T14:00:00.000Z',
      });
      expect(dto.id, equals('rpc-id-123'));
    });

    test('reads id from id key (direct query)', () {
      final dto = LockoutSessionDto.fromJson({
        'id': 'direct-id-456',
        'user_id': 'user-1',
        'started_at': '2024-01-01T10:00:00.000Z',
        'ends_at': '2024-01-01T14:00:00.000Z',
      });
      expect(dto.id, equals('direct-id-456'));
    });

    test('lockout_id takes precedence over id', () {
      final dto = LockoutSessionDto.fromJson({
        'lockout_id': 'rpc-id',
        'id': 'direct-id',
        'user_id': 'user-1',
        'started_at': '2024-01-01T10:00:00.000Z',
        'ends_at': '2024-01-01T14:00:00.000Z',
      });
      expect(dto.id, equals('rpc-id'));
    });
  });

  group('Freezed DTOs', () {
    test('LockoutDailyStatsDto fromJson', () {
      final dto = LockoutDailyStatsDto.fromJson({
        'day': '2024-01-01',
        'minutes': 120,
        'session_count': 3,
        'avg_score': 85.5,
      });
      expect(dto.day, equals('2024-01-01'));
      expect(dto.minutes, equals(120));
      expect(dto.sessionCount, equals(3));
      expect(dto.avgScore, equals(85.5));
    });

    test('LockoutMonthlySummaryDto fromJson', () {
      final dto = LockoutMonthlySummaryDto.fromJson({
        'total_minutes': 600,
        'avg_score': 78.2,
        'session_count': 15,
        'max_duration_minutes': 240,
      });
      expect(dto.totalMinutes, equals(600));
      expect(dto.avgScore, equals(78.2));
      expect(dto.sessionCount, equals(15));
      expect(dto.maxDurationMinutes, equals(240));
    });

    test('LockoutActivityStatsDto fromJson', () {
      final dto = LockoutActivityStatsDto.fromJson({
        'action_text': 'Going for a walk',
        'total_minutes': 180,
        'session_count': 5,
      });
      expect(dto.actionText, equals('Going for a walk'));
      expect(dto.totalMinutes, equals(180));
      expect(dto.sessionCount, equals(5));
    });
  });
}
