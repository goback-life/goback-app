import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/is_authenticated_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_authenticated_provider.g.dart';

@Riverpod(keepAlive: false)
bool isAuthenticated(Ref ref) {
  final useCase = IsAuthenticatedUseCase(
    repository: ref.watch(authRepositoryProvider),
  );
  return useCase.execute();
}
