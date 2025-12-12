import 'package:cloudless/core/features/auth/data/providers/auth_service_provider.dart';
import 'package:cloudless/core/features/auth/data/repositories/auth_repository.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_provider.g.dart';

@Riverpod(keepAlive: false)
AuthRepositoryContract authRepository(Ref ref) {
  return AuthRepository(authService: ref.watch(authServiceProvider));
}
