import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/delete_account_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_account_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> deleteAccount(Ref ref) async {
  final useCase = DeleteAccountUseCase(
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
