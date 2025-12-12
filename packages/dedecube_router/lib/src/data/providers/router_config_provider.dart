import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_config_provider.g.dart';

@Riverpod(keepAlive: true)
class RouterConfigNotifier extends _$RouterConfigNotifier {
  RouterConfigNotifier();

  @override
  RouterConfig build() {
    return RouterConfig();
  }

  set routerConfig(RouterConfig newConfig) {
    state = newConfig;
  }
}
