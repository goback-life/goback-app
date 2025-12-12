import 'package:cloudless/core/exceptions/main_exception.dart';

class UnhandledException extends MainException {
  const UnhandledException(super.message, {super.code, this.cause});

  final Object? cause;

  @override
  String toString() => cause != null
      ? 'UnhandledException: $message (cause: $cause)${code != null ? ' (code: $code)' : ''}'
      : super.toString();
}
