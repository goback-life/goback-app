class RouterDuplicateException implements Exception {
  RouterDuplicateException({
    required this.property,
    required this.value,
  });

  /// The property that has a duplicate (e.g. 'path' or 'name').
  final String property;

  /// The duplicate value detected.
  final String value;

  @override
  String toString() =>
      'RouterDuplicateException: Duplicate $property found: "$value".';
}
