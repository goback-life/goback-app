import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/validate_session_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'validate_session_provider.g.dart';

/// Provider for validating the current authentication session.
///
/// Returns true if the session is valid, false if invalid/user deleted.
@Riverpod(keepAlive: false)
Future<Result<bool>> validateSession(Ref ref) async {
  final useCase = ValidateSessionUseCase(
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
