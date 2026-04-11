/// Permission, Time Limit, Share, and Onboarding refactoring verification test.
///
/// Documents public API contracts and structural invariants that must
/// survive refactoring. These are compile-time and structural checks
/// (no runtime device/platform dependencies).
library;

import 'package:cloudless/core/features/permission/data/exceptions/camera_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/contact_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/gallery_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_check_status_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_open_settings_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_rationale_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_request_exception.dart';
import 'package:cloudless/core/features/permission/data/mappers/permission_status_mapper.dart';
import 'package:cloudless/core/features/permission/data/mappers/permission_type_mapper.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_service_contract.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/check_permission_status_use_case.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/open_app_settings_use_case.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/request_permission_use_case.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/should_show_rationale_use_case.dart';
import 'package:cloudless/core/features/onboarding/data/storables/onboarding_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_phase_storable.dart';
import 'package:cloudless/core/features/share/data/services/share_card_capture_service.dart';
import 'package:cloudless/core/features/share/domain/providers/pending_share_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── PermissionType enum ──────────────────────────────────────────────
  group('PermissionType', () {
    test('has all expected values', () {
      expect(
        PermissionType.values,
        containsAll([
          PermissionType.camera,
          PermissionType.gallery,
          PermissionType.storage,
          PermissionType.contact,
          PermissionType.notification,
        ]),
      );
      expect(PermissionType.values.length, 5);
    });
  });

  // ── PermissionStatus enum ────────────────────────────────────────────
  group('PermissionStatus', () {
    test('has all expected values', () {
      expect(
        PermissionStatus.values,
        containsAll([
          PermissionStatus.denied,
          PermissionStatus.granted,
          PermissionStatus.permanentlyDenied,
          PermissionStatus.restricted,
          PermissionStatus.limited,
          PermissionStatus.provisional,
          PermissionStatus.notDetermined,
        ]),
      );
      expect(PermissionStatus.values.length, 7);
    });
  });

  // ── PermissionResultModel ────────────────────────────────────────────
  group('PermissionResultModel', () {
    test('can be constructed with required fields', () {
      final model = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.granted,
      );
      expect(model.type, PermissionType.camera);
      expect(model.status, PermissionStatus.granted);
      expect(model.message, isNull);
    });

    test('supports optional message field', () {
      final model = PermissionResultModel(
        type: PermissionType.gallery,
        status: PermissionStatus.denied,
        message: 'test',
      );
      expect(model.message, 'test');
    });

    test('copyWith preserves unmodified fields', () {
      final original = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.granted,
      );
      final copy = original.copyWith(status: PermissionStatus.denied);
      expect(copy.type, PermissionType.camera);
      expect(copy.status, PermissionStatus.denied);
    });

    test('isGranted is true for granted and limited', () {
      final granted = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.granted,
      );
      final limited = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.limited,
      );
      final denied = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.denied,
      );
      expect(granted.isGranted, isTrue);
      expect(limited.isGranted, isTrue);
      expect(denied.isGranted, isFalse);
    });

    test('isDenied only for denied status', () {
      final denied = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.denied,
      );
      final granted = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.granted,
      );
      expect(denied.isDenied, isTrue);
      expect(granted.isDenied, isFalse);
    });

    test('isPermanentlyDenied only for permanentlyDenied status', () {
      final permDenied = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.permanentlyDenied,
      );
      expect(permDenied.isPermanentlyDenied, isTrue);
    });

    test('isNotDetermined only for notDetermined status', () {
      final notDet = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.notDetermined,
      );
      expect(notDet.isNotDetermined, isTrue);
    });

    test('JSON round-trip', () {
      final model = PermissionResultModel(
        type: PermissionType.camera,
        status: PermissionStatus.granted,
        message: 'ok',
      );
      final json = model.toJson();
      final restored = PermissionResultModel.fromJson(json);
      expect(restored, model);
    });
  });

  // ── PermissionStatusMapper ───────────────────────────────────────────
  group('PermissionStatusMapper', () {
    test('class is accessible', () {
      // Verifies the mapper class exists and has the expected static method.
      expect(PermissionStatusMapper.fromPermissionHandlerStatus, isNotNull);
    });
  });

  // ── PermissionTypeMapper ─────────────────────────────────────────────
  group('PermissionTypeMapper', () {
    test('class is accessible', () {
      expect(PermissionTypeMapper.toHandler, isNotNull);
    });
  });

  // ── Permission Exceptions hierarchy ──────────────────────────────────
  group('Permission Exceptions', () {
    test('all extend PermissionException', () {
      expect(CameraPermissionDeniedException() is PermissionException, isTrue);
      expect(ContactPermissionDeniedException() is PermissionException, isTrue);
      expect(GalleryPermissionDeniedException() is PermissionException, isTrue);
      expect(PermissionCheckStatusException() is PermissionException, isTrue);
      expect(PermissionOpenSettingsException() is PermissionException, isTrue);
      expect(PermissionRationaleException() is PermissionException, isTrue);
      expect(PermissionRequestException() is PermissionException, isTrue);
    });

    test('CameraPermissionDeniedException has isPermanentlyDenied field', () {
      final ex = CameraPermissionDeniedException(isPermanentlyDenied: true);
      expect(ex.isPermanentlyDenied, isTrue);
      expect(ex.message, 'Camera permission denied.');
    });

    test('ContactPermissionDeniedException has isPermanentlyDenied field', () {
      final ex = ContactPermissionDeniedException(isPermanentlyDenied: true);
      expect(ex.isPermanentlyDenied, isTrue);
      expect(ex.message, 'Contacts permission denied.');
    });

    test('GalleryPermissionDeniedException has isPermanentlyDenied field', () {
      final ex = GalleryPermissionDeniedException(isPermanentlyDenied: true);
      expect(ex.isPermanentlyDenied, isTrue);
      expect(ex.message, 'Gallery permission denied.');
    });
  });

  // ── Contracts ────────────────────────────────────────────────────────
  group('Contracts', () {
    test('PermissionRepositoryContract is abstract', () {
      // Just verifying that the import resolves - contract is abstract.
      expect(PermissionRepositoryContract, isNotNull);
    });

    test('PermissionServiceContract is abstract', () {
      expect(PermissionServiceContract, isNotNull);
    });
  });

  // ── Use Cases ────────────────────────────────────────────────────────
  group('Use Cases', () {
    test('CheckPermissionStatusUseCase is accessible', () {
      expect(CheckPermissionStatusUseCase, isNotNull);
    });

    test('RequestPermissionUseCase is accessible', () {
      expect(RequestPermissionUseCase, isNotNull);
    });

    test('OpenAppSettingsUseCase is accessible', () {
      expect(OpenAppSettingsUseCase, isNotNull);
    });

    test('ShouldShowRationaleUseCase is accessible', () {
      expect(ShouldShowRationaleUseCase, isNotNull);
    });
  });

  // ── Share feature ────────────────────────────────────────────────────
  group('Share feature', () {
    test('ShareCardCaptureService is accessible', () {
      expect(ShareCardCaptureService, isNotNull);
    });

    test('pendingShareProvider is a StateProvider', () {
      expect(pendingShareProvider, isA<StateProvider>());
    });
  });

  // ── Onboarding storables ─────────────────────────────────────────────
  group('Onboarding storables', () {
    test('OnboardingCompletedStorable has correct key', () {
      final storable = OnboardingCompletedStorable();
      expect(storable.key, 'onboarding_v2_completed');
    });

    test('TutorialCompletedStorable has correct key', () {
      final storable = TutorialCompletedStorable();
      expect(storable.key, 'tutorial_v1_completed');
    });

    test('TutorialPhaseStorable has correct key', () {
      final storable = TutorialPhaseStorable();
      expect(storable.key, 'tutorial_v1_phase');
    });
  });
}
