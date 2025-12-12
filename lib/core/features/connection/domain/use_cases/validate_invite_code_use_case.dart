import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ValidateInviteCodeUseCase
    implements UseCaseContract<Result<InviteValidationResult>> {
  const ValidateInviteCodeUseCase({
    required this.repository,
    required this.inviteCode,
  });

  final ConnectionRepositoryContract repository;
  final String inviteCode;

  @override
  Future<Result<InviteValidationResult>> execute() async {
    return await repository.validateInviteCode(inviteCode);
  }
}
