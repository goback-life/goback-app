import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:cloudless/core/models/user_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetCurrentUserUseCase
    implements UseCaseContract<FutureResult<UserModel>> {
  const GetCurrentUserUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  FutureResult<UserModel> execute() {
    return repository.getCurrentUser();
  }
}
