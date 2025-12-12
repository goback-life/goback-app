import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/validate_invite_code_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'validate_invite_code_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<InviteValidationResult>> validateInviteCode(
  Ref ref,
  String inviteCode,
) async {
  final useCase = ValidateInviteCodeUseCase(
    repository: ref.watch(connectionRepositoryProvider),
    inviteCode: inviteCode,
  );
  return await useCase.execute();
}
