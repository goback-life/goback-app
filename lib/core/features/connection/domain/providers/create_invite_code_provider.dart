import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/create_invite_code_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_invite_code_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<String>> createInviteCode(Ref ref, {int expiryHours = 72}) async {
  final useCase = CreateInviteCodeUseCase(
    repository: ref.watch(connectionRepositoryProvider),
    expiryHours: expiryHours,
  );
  return await useCase.execute();
}
