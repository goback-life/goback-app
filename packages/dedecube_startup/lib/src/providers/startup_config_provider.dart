import 'package:dedecube_startup/src/configs/startup_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_config_provider.g.dart';

@Riverpod(keepAlive: true)
class StartupConfigNotifier extends _$StartupConfigNotifier {
  StartupConfigNotifier();

  @override
  StartupConfig build() {
    return StartupConfig();
  }

  set startupConfig(StartupConfig newConfig) {
    state = newConfig;
  }
}
