import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_repository_contract.dart';

class InitializeUseCase implements UseCaseContract<void> {
  const InitializeUseCase({
    required this.repository,
    this.filename = '.env',
  });

  final EnvironmentRepositoryContract repository;
  final String filename;

  @override
  Future<void> execute() async {
    return await repository.initialize(filename: filename);
  }
}
