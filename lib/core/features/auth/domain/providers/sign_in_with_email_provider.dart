import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/sign_in_with_email_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_with_email_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> signInWithEmail(Ref ref, String email) async {
  final useCase = SignInWithEmailUseCase(
    email: email,
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
