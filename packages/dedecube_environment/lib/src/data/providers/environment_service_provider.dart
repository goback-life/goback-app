import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/services/environment_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'environment_service_provider.g.dart';

@Riverpod(keepAlive: false)
EnvironmentService environmentService(Ref ref) {
  return EnvironmentService(
    ref,
  );
}
