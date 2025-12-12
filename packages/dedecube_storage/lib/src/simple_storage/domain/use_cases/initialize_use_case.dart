import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

class InitializeUseCase implements UseCaseContract<void> {
  const InitializeUseCase({
    required this.repository,
  });

  final SimpleStorageRepositoryContract repository;

  @override
  Future<void> execute() async {
    return await repository.initialize();
  }
}
