import 'package:dedecube_logger/src/data/configs/logger_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_config_provider.g.dart';

@Riverpod(keepAlive: true)
class LoggerConfigNotifier extends _$LoggerConfigNotifier {
  LoggerConfigNotifier();

  @override
  LoggerConfig build() {
    return LoggerConfig();
  }

  set loggerConfig(LoggerConfig newConfig) {
    state = newConfig;
  }
}
