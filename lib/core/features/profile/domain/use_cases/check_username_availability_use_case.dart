import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class CheckUsernameAvailabilityUseCase
    implements UseCaseContract<FutureResult<bool>> {
  const CheckUsernameAvailabilityUseCase({
    required this.username,
    required this.repository,
  });

  final String username;
  final ProfileRepositoryContract repository;

  @override
  FutureResult<bool> execute() async {
    return repository.checkUsernameAvailability(username);
  }
}
