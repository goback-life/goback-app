import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';
import 'package:dedecube_core/dedecube_core.dart';

class RemoveConnectionUseCase implements UseCaseContract<Result<bool>> {
  const RemoveConnectionUseCase({
    required this.repository,
    required this.userId,
  });

  final ConnectionRepositoryContract repository;
  final String userId;

  @override
  Future<Result<bool>> execute() async {
    if (userId.isEmpty) {
      return Result.failure(
        const ConnectionException('User ID cannot be empty'),
      );
    }

    return await repository.removeConnection(userId);
  }
}
