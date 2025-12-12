import 'package:dedecube_themify/src/data/configs/themify_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'themify_config_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemifyConfigNotifier extends _$ThemifyConfigNotifier {
  ThemifyConfigNotifier();

  @override
  ThemifyConfig build() {
    return ThemifyConfig();
  }

  set themeConfig(ThemifyConfig newConfig) {
    state = newConfig;
  }
}
