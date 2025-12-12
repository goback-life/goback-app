class UnsupportedStorageTypeException implements Exception {
  UnsupportedStorageTypeException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedStorageTypeException: $message';
}
