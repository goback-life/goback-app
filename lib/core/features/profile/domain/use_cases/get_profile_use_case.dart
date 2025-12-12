import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetProfileUseCase
    implements UseCaseContract<FutureResult<ProfileModel?>> {
  const GetProfileUseCase({required this.userId, required this.repository});

  final String userId;
  final ProfileRepositoryContract repository;

  @override
  FutureResult<ProfileModel?> execute() async {
    return repository.getProfile(userId);
  }
}
