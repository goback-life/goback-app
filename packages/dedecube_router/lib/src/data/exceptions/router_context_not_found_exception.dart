class RouterContextNotFoundException implements Exception {
  RouterContextNotFoundException();

  @override
  String toString() =>
      'RouterContextNotFoundException: Unable to retrieve the current context.';
}
