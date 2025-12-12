class TranslatorFileNotFoundException implements Exception {
  TranslatorFileNotFoundException(this.filePath);
  final String filePath;

  @override
  String toString() =>
      'TranslatorFileNotFoundException: Unable to retrieve the file $filePath.';
}
