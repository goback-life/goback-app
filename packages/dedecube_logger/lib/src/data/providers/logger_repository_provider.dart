import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_service_provider.dart';
import 'package:dedecube_logger/src/data/repositories/logger_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_repository_provider.g.dart';

@Riverpod(keepAlive: true)
LoggerRepository loggerRepository(
  Ref ref,
) {
  return LoggerRepository(
    loggerService: ref.watch(loggerServiceProvider),
  );
}
