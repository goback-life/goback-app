abstract class MainException implements Exception {
  const MainException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code != null ? '$message (code: $code)' : message;
}
