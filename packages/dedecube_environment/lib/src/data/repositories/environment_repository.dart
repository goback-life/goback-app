import 'package:dedecube_environment/src/data/services/environment_service.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_repository_contract.dart';

class EnvironmentRepository implements EnvironmentRepositoryContract {
  const EnvironmentRepository({required this.environmentService});

  final EnvironmentService environmentService;

  @override
  Future<void> initialize({String filename = '.env'}) async {
    return await environmentService.initialize(filename: filename);
  }

  @override
  String? envString(String key, [String? defaultValue]) {
    return environmentService.envString(key, defaultValue);
  }

  @override
  int? envInt(String key, [int? defaultValue]) {
    return environmentService.envInt(key, defaultValue);
  }

  @override
  double? envDouble(String key, [double? defaultValue]) {
    return environmentService.envDouble(key, defaultValue);
  }

  @override
  bool? envBool(String key, [bool? defaultValue]) {
    return environmentService.envBool(key, defaultValue);
  }
}
