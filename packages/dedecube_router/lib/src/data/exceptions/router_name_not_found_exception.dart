class RouterNameNotFoundException implements Exception {
  RouterNameNotFoundException();

  @override
  String toString() =>
      'RouterNameNotFoundException: Unable to retrieve the current name.';
}
