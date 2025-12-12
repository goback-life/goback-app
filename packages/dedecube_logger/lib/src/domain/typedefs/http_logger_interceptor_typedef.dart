import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';

/// HTTP logger interceptor abstraction
///
/// Provides a way to intercept and log HTTP requests and responses
/// without exposing the underlying implementation details.
typedef HttpLoggerInterceptor = TalkerDioLogger;
