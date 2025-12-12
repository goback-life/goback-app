import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/providers/router_config_provider.dart';
import 'package:dedecube_router/src/data/services/router_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_service_provider.g.dart';

@Riverpod(keepAlive: true)
RouterService routerService(Ref ref) {
  return RouterService(
    ref,
    config: ref.watch(routerConfigNotifierProvider),
  );
}
