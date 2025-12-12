import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/providers/router_service_provider.dart';
import 'package:dedecube_router/src/data/repositories/router_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_repository_provider.g.dart';

@Riverpod(keepAlive: true)
RouterRepository routerRepository(
  Ref ref,
) {
  return RouterRepository(
    routerService: ref.watch(routerServiceProvider),
  );
}
