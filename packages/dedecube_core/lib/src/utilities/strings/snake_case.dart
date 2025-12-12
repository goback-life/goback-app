extension SnakeCase on String {
  /// Converts this CamelCase string to snake_case.
  ///
  /// For example, "DefaultTheme".snakeCase() returns "default_theme".
  String snakeCase() {
    final regex = RegExp(r'(?<=[a-z])[A-Z]');
    return replaceAllMapped(regex, (match) => '_${match.group(0)}')
        .toLowerCase();
  }
}
