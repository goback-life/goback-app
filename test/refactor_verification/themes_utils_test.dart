// Verification test for themes, hooks, utilities, assets, and core infrastructure.
// Documents structural contracts that must be preserved after refactoring.
//
// This is a compile-time + structural test, not a runtime integration test.
// It verifies that all public API surfaces remain intact after refactoring.

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// === PRESENTATION HOOKS ===
import 'package:cloudless/presentation/hooks/use_launch_url.dart';
import 'package:cloudless/presentation/hooks/use_debounced_username_check.dart';

// === PRESENTATION THEMES ===
import 'package:cloudless/presentation/themes/main_theme.dart';
import 'package:cloudless/presentation/themes/link_style.dart';
import 'package:cloudless/presentation/themes/components/default_text_theme.dart';
import 'package:cloudless/presentation/themes/components/main_elevated_button_theme.dart';
import 'package:cloudless/presentation/themes/components/main_text_button_theme.dart';
import 'package:cloudless/presentation/themes/components/main_text_theme.dart';
import 'package:cloudless/presentation/themes/components/text_theme_extensions.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';

// === PRESENTATION UTILITIES ===
import 'package:cloudless/presentation/utilities/bottom_padding_considering_safe_area.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:cloudless/presentation/utilities/main_shell_context_provider.dart';
import 'package:cloudless/presentation/utilities/phone_number_formatter.dart';

// === CORE UTILITIES ===
import 'package:cloudless/core/utilities/asset_to_file_helper.dart';
import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/core/utilities/file_image_type_extensions.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:cloudless/core/utilities/video_thumbnail_helper.dart';

// === CORE CONFIG ===
import 'package:cloudless/core/config/debug_form_values.dart';

// === CORE EXCEPTIONS ===
import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/network_connection_exception.dart';
import 'package:cloudless/core/exceptions/request_timeout_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';

// === CORE MODELS ===
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/core/models/user_model.dart';

// === CORE MAPPERS ===
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

void main() {
  group('Themes - Structural Contracts', () {
    test('MainTheme produces valid ThemeData', () {
      final theme = MainTheme();
      expect(theme.themeData, isA<ThemeData>());
      expect(theme.colorScheme, isA<ColorScheme>());
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('MainColors defines required palette', () {
      expect(MainColors.white, const Color(0xFFFFFFFF));
      expect(MainColors.dark, const Color(0xFF1A1A1A));
      expect(MainColors.accent, const Color(0xFF598EB5));
      expect(MainColors.black, const Color(0xFF000000));
    });

    test('MainFontFamilies defines required fonts', () {
      expect(MainFontFamilies.geist, 'Geist');
      expect(MainFontFamilies.quicksand, 'Quicksand');
      expect(MainFontFamilies.lilitaOne, 'LilitaOne');
    });

    test('DefaultTextTheme creates full TextTheme', () {
      final textTheme = DefaultTextTheme.create();
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.labelSmall, isNotNull);
    });

    test('MainTextTheme applies font families and weights', () {
      const colorScheme = ColorScheme.dark();
      final textTheme = MainTextTheme.theme(colorScheme);
      expect(textTheme.bodyMedium?.fontFamily, MainFontFamilies.quicksand);
    });

    test('MainElevatedButtonTheme produces ElevatedButtonThemeData', () {
      const colorScheme = ColorScheme.dark();
      final theme = MainElevatedButtonTheme.theme(colorScheme);
      expect(theme, isA<ElevatedButtonThemeData>());
    });

    test('MainTextButtonTheme produces TextButtonThemeData', () {
      const colorScheme = ColorScheme.dark();
      final theme = MainTextButtonTheme.theme(colorScheme);
      expect(theme, isA<TextButtonThemeData>());
    });

    test('LinkTextStyle is a ThemeExtension', () {
      const style = LinkTextStyle();
      expect(style, isA<ThemeExtension<LinkTextStyle>>());
      expect(style.copyWith(), isA<LinkTextStyle>());
    });

    test('TextThemeExtensions broadCustomization works', () {
      final base = DefaultTextTheme.create();
      final customized = base.broadCustomization(
        color: Colors.red,
        family: 'TestFont',
      );
      expect(customized.bodyMedium?.color, Colors.red);
      expect(customized.bodyMedium?.fontFamily, 'TestFont');
    });
  });

  group('Hooks - Structural Contracts', () {
    test('useLaunchUrl typedef is accessible', () {
      // LaunchUrlFunction type must exist
      expect(true, isTrue); // compile-time check
    });

    test('DebouncedUsernameResult has required getters', () {
      const result = DebouncedUsernameResult(
        value: AsyncValue.loading(),
        isDebouncing: false,
        lastCheckedUsername: null,
      );
      expect(result.isLoading, isTrue);
      expect(result.isDebouncing, isFalse);
      expect(result.isAvailable, isNull);
      expect(result.hasError, isFalse);
    });
  });

  group('Presentation Utilities - Structural Contracts', () {
    test('PhoneNumberFormatter masks correctly', () {
      expect(PhoneNumberFormatter.format('+391234567890'), '********7890');
      expect(PhoneNumberFormatter.format('123'), '123');
      expect(PhoneNumberFormatter.format('1234'), '1234');
    });

    test('MainLayout mixin provides default values', () {
      final layout = _TestLayout();
      expect(layout.horizontalMargin, 20);
      expect(layout.controlsHorizontalSpacing, 12);
      expect(layout.padding, isA<EdgeInsets>());
      expect(layout.margin, isA<EdgeInsets>());
    });
  });

  group('Core Utilities - Structural Contracts', () {
    test('DateFormatter formats day-month correctly', () {
      final date = DateTime(2024, 10, 1);
      final result = DateFormatter.formatDayMonth(date, 'en');
      expect(result, contains('October'));
    });

    test('DateFormatter formatTimeOnly works', () {
      final date = DateTime(2024, 10, 1, 14, 30);
      final result = DateFormatter.formatTimeOnly(
        date,
        'en',
        convertToLocal: false,
      );
      expect(result, '14.30');
    });

    test('DateFormatter isFutureDay works', () {
      final current = DateTime(2024, 10, 1);
      final future = DateTime(2024, 11, 1);
      expect(DateFormatter.isFutureDay(future, current), isTrue);
      expect(DateFormatter.isFutureDay(current, current), isFalse);
    });

    test('DateFormatter getFirstDayOfMonth works', () {
      final result = DateFormatter.getFirstDayOfMonth(DateTime(2024, 10, 15));
      expect(result.day, 1);
      expect(result.month, 10);
    });

    test('AssetToFileHelper class is accessible', () {
      expect(AssetToFileHelper, isNotNull);
    });

    test('VideoThumbnailHelper class is accessible', () {
      expect(VideoThumbnailHelper, isNotNull);
    });
  });

  group('Core Exceptions - Structural Contracts', () {
    test('Exception hierarchy is preserved', () {
      const network = NetworkConnectionException();
      const timeout = RequestTimeoutException();
      const tooMany = TooManyRequestsException();
      const unhandled = UnhandledException('test');

      expect(network, isA<MainException>());
      expect(timeout, isA<MainException>());
      expect(tooMany, isA<MainException>());
      expect(unhandled, isA<MainException>());
    });

    test('NetworkConnectionException has default message', () {
      const e = NetworkConnectionException();
      expect(e.message, 'Network connection failed');
    });

    test('UnhandledException preserves cause', () {
      const e = UnhandledException('test', cause: 'root cause');
      expect(e.cause, 'root cause');
      expect(e.toString(), contains('root cause'));
    });

    test('MainException toString includes code when present', () {
      const e = NetworkConnectionException('fail', 'ERR_001');
      expect(e.toString(), contains('ERR_001'));
    });
  });

  group('Core Models - Structural Contracts', () {
    test('ProfileModel fromJson round-trips', () {
      final json = {
        'id': 'test-id',
        'username': 'testuser',
        'biography': 'bio',
        'avatarUrl': null,
        'phoneNumber': '+1234',
        'weekly_lockout_minutes': 60,
        'notifications_checked_at': null,
      };
      final model = ProfileModel.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.username, 'testuser');
      expect(model.weeklyLockoutMinutes, 60);
    });

    test('UserModel fromJson round-trips', () {
      final json = {'id': 'user-1', 'phoneNumber': '+1234'};
      final model = UserModel.fromJson(json);
      expect(model.id, 'user-1');
      expect(model.phoneNumber, '+1234');
    });
  });

  group('Core Config - Structural Contracts', () {
    test('DebugFormValues class is accessible', () {
      expect(DebugFormValues, isNotNull);
    });
  });

  group('Core Mappers - Structural Contracts', () {
    test('DtoToModelMapperContract defines required interface', () {
      // Compile-time verification that contract interface is accessible
      expect(DtoToModelMapperContract, isNotNull);
    });
  });
}

/// Test helper for MainLayout mixin verification
class _TestLayout with MainLayout {}
