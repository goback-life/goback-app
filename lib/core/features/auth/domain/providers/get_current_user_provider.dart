import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:cloudless/core/models/user_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_current_user_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<UserModel>> getCurrentUser(Ref ref) async {
  final useCase = GetCurrentUserUseCase(
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
