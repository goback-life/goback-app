import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_config_provider.dart';
import 'package:dedecube_logger/src/data/services/logger_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_service_provider.g.dart';

@Riverpod(keepAlive: true)
LoggerService loggerService(Ref ref) {
  return LoggerService(
    ref,
    config: ref.watch(loggerConfigNotifierProvider),
  );
}
