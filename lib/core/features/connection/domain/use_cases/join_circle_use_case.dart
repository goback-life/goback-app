import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class JoinCircleUseCase implements UseCaseContract<Result<bool>> {
  const JoinCircleUseCase({required this.repository, required this.inviteCode});

  final ConnectionRepositoryContract repository;
  final String inviteCode;

  @override
  Future<Result<bool>> execute() async {
    return await repository.joinCircle(inviteCode);
  }
}
