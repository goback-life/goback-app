class EnvironmentFileLoadException implements Exception {
  EnvironmentFileLoadException(this.fileName);
  final String fileName;

  @override
  String toString() =>
      'EnvironmentFileLoadException: Error loading environment file: $fileName';
}
