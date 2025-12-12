import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetCircleMembersUseCase
    implements UseCaseContract<Result<List<ConnectionMemberModel>>> {
  const GetCircleMembersUseCase({required this.repository});

  final ConnectionRepositoryContract repository;

  @override
  Future<Result<List<ConnectionMemberModel>>> execute() async {
    return await repository.getCircleMembers();
  }
}
