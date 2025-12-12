import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class HasCompletedProfileUseCase
    implements UseCaseContract<FutureResult<bool>> {
  const HasCompletedProfileUseCase({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final ProfileRepositoryContract repository;

  @override
  FutureResult<bool> execute() {
    return repository.hasCompletedProfile(userId);
  }
}
