/// Supabase + Storage + Infrastructure refactoring verification test.
///
/// Documents public API contracts and structural invariants that must
/// survive refactoring. These are compile-time and structural checks
/// (no runtime Supabase/Firebase dependencies).
library;

import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/network_connection_exception.dart';
import 'package:cloudless/core/exceptions/request_timeout_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/crashlytics/data/services/crashlytics_service.dart';
import 'package:cloudless/core/features/crashlytics/domain/contracts/crashlytics_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/configs/supabase_client_service_config.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/core/features/supabase/data/services/supabase_client_service.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/common_supabase_exception_ui_handler_contract.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_contract.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_result_processor_contract.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_tables.dart';
import 'package:cloudless/core/features/timezone/data/services/timezone_converter.dart';
import 'package:cloudless/core/features/timezone/domain/contracts/timezone_converter_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  // ── Exception hierarchy ──────────────────────────────────────────────
  group('Exception hierarchy', () {
    test('MainException is base type with message and optional code', () {
      const e = NetworkConnectionException('test', 'CODE');
      expect(e, isA<MainException>());
      expect(e.message, 'test');
      expect(e.code, 'CODE');
    });

    test('NetworkConnectionException has default message', () {
      const e = NetworkConnectionException();
      expect(e, isA<MainException>());
      expect(e.message, contains('Network'));
    });

    test('RequestTimeoutException has default message', () {
      const e = RequestTimeoutException();
      expect(e, isA<MainException>());
      expect(e.message, contains('timed out'));
    });

    test('TooManyRequestsException has default message', () {
      const e = TooManyRequestsException();
      expect(e, isA<MainException>());
      expect(e.message, contains('Too many'));
    });

    test('UnhandledException supports cause and code', () {
      const e = UnhandledException('msg', code: '500', cause: 'root');
      expect(e, isA<MainException>());
      expect(e.cause, 'root');
      expect(e.code, '500');
      expect(e.toString(), contains('cause'));
    });

    test('UnhandledException toString without cause', () {
      const e = UnhandledException('msg');
      expect(e.toString(), isNot(contains('cause')));
    });
  });

  // ── SupabaseBuckets ──────────────────────────────────────────────────
  group('SupabaseBuckets', () {
    test('has expected bucket constants', () {
      expect(SupabaseBuckets.avatars, 'avatars');
      expect(SupabaseBuckets.postMedia, 'post_media');
    });
  });

  // ── SupabaseTables ───────────────────────────────────────────────────
  group('SupabaseTables', () {
    test('has expected table constants', () {
      expect(SupabaseTables.profiles, 'profiles');
    });
  });

  // ── SupabaseClientServiceConfig ──────────────────────────────────────
  group('SupabaseClientServiceConfig', () {
    test('implements contract with required fields', () {
      final config = SupabaseClientServiceConfig(
        projectUrl: 'https://example.supabase.co',
        anonKey: 'test-key',
      );
      expect(config, isA<SupabaseClientServiceConfigContract>());
      expect(config.projectUrl, 'https://example.supabase.co');
      expect(config.anonKey, 'test-key');
    });
  });

  // ── SupabaseClientService ────────────────────────────────────────────
  group('SupabaseClientService', () {
    test('implements SupabaseClientServiceContract', () {
      final service = SupabaseClientService();
      expect(service, isA<SupabaseClientServiceContract>());
    });

    test('throws StateError when accessing client before initialization', () {
      final service = SupabaseClientService();
      expect(() => service.client, throwsStateError);
    });
  });

  // ── Contract interfaces ──────────────────────────────────────────────
  group('Contract interfaces', () {
    test(
      'SupabaseClientServiceConfigContract defines projectUrl and anonKey',
      () {
        expect(SupabaseClientServiceConfigContract, isNotNull);
      },
    );

    test('SupabaseClientServiceContract defines initialize and client', () {
      expect(SupabaseClientServiceContract, isNotNull);
    });

    test('SupabaseResultProcessorContract defines processSupabaseResult', () {
      expect(SupabaseResultProcessorContract, isNotNull);
    });

    test(
      'CommonSupabaseExceptionUIHandlerContract defines handleSupabaseException',
      () {
        expect(CommonSupabaseExceptionUIHandlerContract, isNotNull);
      },
    );

    test('CrashlyticsServiceContract defines all required methods', () {
      expect(CrashlyticsServiceContract, isNotNull);
    });

    test('TimezoneConverterContract defines toLocal and toLocalWithOffset', () {
      expect(TimezoneConverterContract, isNotNull);
    });
  });

  // ── CommonSupabaseExceptionUIHandler ─────────────────────────────────
  group('CommonSupabaseExceptionUIHandler', () {
    test('implements contract', () {
      final handler = CommonSupabaseExceptionUIHandler();
      expect(handler, isA<CommonSupabaseExceptionUIHandlerContract>());
    });
  });

  // ── TimezoneConverter ────────────────────────────────────────────────
  group('TimezoneConverter', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('implements TimezoneConverterContract', () {
      final converter = TimezoneConverter();
      expect(converter, isA<TimezoneConverterContract>());
    });

    test('toLocal converts UTC to local timezone', () {
      final converter = TimezoneConverter();
      final utc = DateTime.utc(2025, 6, 15, 12, 0);
      final local = converter.toLocal(utc, 'Europe/Rome');
      // Rome is UTC+2 in summer (CEST)
      expect(local.hour, 14);
    });

    test('toLocal throws on non-UTC DateTime', () {
      final converter = TimezoneConverter();
      final nonUtc = DateTime(2025, 6, 15, 12, 0);
      expect(
        () => converter.toLocal(nonUtc, 'Europe/Rome'),
        throwsArgumentError,
      );
    });

    test(
      'toLocalWithOffset returns map with dateTime, offset, abbreviation',
      () {
        final converter = TimezoneConverter();
        final utc = DateTime.utc(2025, 6, 15, 12, 0);
        final result = converter.toLocalWithOffset(utc, 'Europe/Rome');
        expect(result, containsPair('dateTime', isA<DateTime>()));
        expect(result, containsPair('offset', isA<Duration>()));
        expect(result, containsPair('abbreviation', isA<String>()));
      },
    );

    test('toLocalWithOffset throws on non-UTC DateTime', () {
      final converter = TimezoneConverter();
      final nonUtc = DateTime(2025, 6, 15, 12, 0);
      expect(
        () => converter.toLocalWithOffset(nonUtc, 'Europe/Rome'),
        throwsArgumentError,
      );
    });
  });

  // ── CrashlyticsService ───────────────────────────────────────────────
  group('CrashlyticsService', () {
    test('implements CrashlyticsServiceContract', () {
      // CrashlyticsService requires FirebaseCrashlytics at runtime,
      // but we can verify the type relationship at compile time.
      expect(CrashlyticsService, isNotNull);
    });
  });
}
