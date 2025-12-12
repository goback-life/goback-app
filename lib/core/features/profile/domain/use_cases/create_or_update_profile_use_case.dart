import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class CreateOrUpdateProfileUseCase
    implements UseCaseContract<FutureResult<ProfileModel>> {
  const CreateOrUpdateProfileUseCase({
    required this.id,
    required this.username,
    required this.repository,
    this.biography,
  });

  final String id;
  final String username;
  final String? biography;
  final ProfileRepositoryContract repository;

  @override
  FutureResult<ProfileModel> execute() async {
    return repository.createOrUpdateProfile(
      id: id,
      username: username,
      biography: biography,
    );
  }
}
