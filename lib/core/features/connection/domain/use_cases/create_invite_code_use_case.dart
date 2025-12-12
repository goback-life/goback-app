import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class CreateInviteCodeUseCase implements UseCaseContract<Result<String>> {
  const CreateInviteCodeUseCase({
    required this.repository,
    this.expiryHours = 72,
  });

  final ConnectionRepositoryContract repository;
  final int expiryHours;

  @override
  Future<Result<String>> execute() async {
    return await repository.createInviteCode(expiryHours: expiryHours);
  }
}
