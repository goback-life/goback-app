import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/providers/environment_service_provider.dart';
import 'package:dedecube_environment/src/data/repositories/environment_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'environment_repository_provider.g.dart';

@Riverpod(keepAlive: false)
EnvironmentRepository environmentRepository(
  Ref ref,
) {
  return EnvironmentRepository(
    environmentService: ref.watch(environmentServiceProvider),
  );
}
