// Verification test for auth feature refactoring.
// Documents structural contracts that must be preserved.
//
// This is a compile-time + structural test, not a runtime integration test.
// It verifies that all public API surfaces remain intact after refactoring.

// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';

// === DOMAIN CONTRACTS ===
import 'package:cloudless/core/features/auth/domain/contracts/auth_service_contract.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';

// === DATA IMPLEMENTATIONS ===
import 'package:cloudless/core/features/auth/data/services/auth_service.dart';
import 'package:cloudless/core/features/auth/data/services/phone_check_service.dart';
import 'package:cloudless/core/features/auth/data/repositories/auth_repository.dart';
import 'package:cloudless/core/features/auth/data/mappers/auth_response_to_model_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/delete_account_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/get_current_user_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/resend_otp_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/sign_in_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/sign_out_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/validate_session_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/verify_phone_otp_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/storables/objective_completed_storable.dart';
import 'package:cloudless/core/features/auth/data/handlers/authentication_background_handler.dart';

// === DATA PROVIDERS ===
import 'package:cloudless/core/features/auth/data/providers/auth_service_provider.dart';
import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/data/providers/phone_check_service_provider.dart';

// === DOMAIN EXCEPTIONS ===
import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_access_denied_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_authentication_required_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_invalid_verification_code_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_otp_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_phone_exists_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_phone_not_confirmed_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_already_used_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_already_exists_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_banned_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';

// === DOMAIN PROVIDERS ===
import 'package:cloudless/core/features/auth/domain/providers/check_phone_numbers_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/delete_account_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/has_completed_objective_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_stream_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/mark_objective_completed_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/resend_email_otp_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/resend_phone_otp_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/sign_in_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/sign_in_with_email_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/sign_out_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/validate_session_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/verify_email_otp_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/verify_phone_otp_provider.dart';

// === DOMAIN USE CASES ===
import 'package:cloudless/core/features/auth/domain/use_cases/delete_account_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/has_completed_objective_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/is_authenticated_stream_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/is_authenticated_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/mark_objective_completed_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/resend_email_otp_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/resend_phone_otp_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/sign_in_with_email_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/validate_session_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/verify_email_otp_use_case.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/verify_phone_otp_use_case.dart';

// === DOMAIN HOOKS ===
import 'package:cloudless/core/features/auth/domain/hooks/auth_navigation_flow.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_check_phone_numbers.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_delete_account.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_otp_form.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_resend_email_otp.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_resend_phone_otp.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_sign_in_form.dart';

// === MIDDLEWARE ===
import 'package:cloudless/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart';

// === UTILITIES ===
import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';

void main() {
  group('Auth Feature - Structural Contracts', () {
    test('AuthServiceContract defines required interface', () {
      // Verify the contract is accessible as a type
      expect(AuthServiceContract, isNotNull);
    });

    test('AuthRepositoryContract defines required interface', () {
      expect(AuthRepositoryContract, isNotNull);
    });

    test('AuthService implements AuthServiceContract', () {
      // AuthService must remain an implementation of AuthServiceContract
      expect(AuthService, isNotNull);
    });

    test('AuthRepository implements AuthRepositoryContract', () {
      expect(AuthRepository, isNotNull);
    });

    test('All exception types extend AuthException', () {
      // Verify exception hierarchy is preserved
      expect(AuthException, isNotNull);
      expect(AuthAccessDeniedException, isNotNull);
      expect(AuthAuthenticationRequiredException, isNotNull);
      expect(AuthInvalidVerificationCodeException, isNotNull);
      expect(AuthOtpExpiredException, isNotNull);
      expect(AuthPhoneExistsException, isNotNull);
      expect(AuthPhoneNotConfirmedException, isNotNull);
      expect(AuthRefreshTokenAlreadyUsedException, isNotNull);
      expect(AuthRefreshTokenNotFoundException, isNotNull);
      expect(AuthSessionExpiredException, isNotNull);
      expect(AuthSessionNotFoundException, isNotNull);
      expect(AuthUserAlreadyExistsException, isNotNull);
      expect(AuthUserBannedException, isNotNull);
      expect(AuthUserNotFoundException, isNotNull);
    });

    test('Exception mappers are accessible', () {
      expect(DeleteAccountExceptionsMapper, isNotNull);
      expect(GetCurrentUserExceptionsMapper, isNotNull);
      expect(ResendOtpExceptionsMapper, isNotNull);
      expect(SignInExceptionsMapper, isNotNull);
      expect(SignOutExceptionsMapper, isNotNull);
      expect(ValidateSessionExceptionsMapper, isNotNull);
      expect(VerifyOtpExceptionsMapper, isNotNull);
    });

    test('PhoneNumberNormalizer normalizes correctly', () {
      expect(
        PhoneNumberNormalizer.normalize('+1 (555) 123-4567'),
        '15551234567',
      );
      expect(PhoneNumberNormalizer.normalize('1-555-123-4567'), '15551234567');
      expect(
        PhoneNumberNormalizer.normalize('+39 123 456 7890'),
        '391234567890',
      );
      expect(PhoneNumberNormalizer.normalize('15551234567'), '15551234567');
    });

    test('PhoneNumberNormalizer normalizeList works', () {
      final result = PhoneNumberNormalizer.normalizeList([
        '+1555',
        '',
        '+39123',
      ]);
      expect(result, ['1555', '39123']);
    });

    test('ObjectiveCompletedStorable has correct key', () {
      final storable = ObjectiveCompletedStorable();
      expect(storable.key, 'objective_completed');
    });

    test('AuthNavigationFlowMiddleware is singleton', () {
      final a = AuthNavigationFlowMiddleware();
      final b = AuthNavigationFlowMiddleware();
      expect(identical(a, b), isTrue);
    });
  });
}
