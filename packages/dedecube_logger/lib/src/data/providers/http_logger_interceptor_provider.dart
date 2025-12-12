import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_service_provider.dart';
import 'package:dedecube_logger/src/domain/typedefs/http_logger_interceptor_typedef.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_logger_interceptor_provider.g.dart';

@Riverpod(keepAlive: false)
HttpLoggerInterceptor httpLoggerInterceptor(
  Ref ref,
) {
  final logger = ref.watch(loggerServiceProvider);

  return logger.createHttpLoggerInterceptor();
}
