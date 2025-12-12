class TranslatorContextNotFoundException implements Exception {
  TranslatorContextNotFoundException();

  @override
  String toString() =>
      'TranslatorContextNotFoundException: Unable to retrieve the current context.';
}
