extension StringAffix on String {
  /// Returns true if this string starts with [search].
  /// If [ignoreCase] is true, the comparison is case-insensitive.
  bool hasStartingPrefix(String search, {bool ignoreCase = false}) => ignoreCase
      ? toLowerCase().startsWith(search.toLowerCase())
      : startsWith(search);

  /// Adds a prefix at the start of a string if it doesn't already start with that prefix.
  ///
  /// Takes a [prefix] string to add at the start and an optional [ignoreCase] parameter
  /// which determines if the prefix check should be case-sensitive.
  ///
  /// Returns the original string if it already starts with the prefix,
  /// otherwise returns a new string with the prefix added at the start.
  String addStartingPrefix(String prefix, {bool ignoreCase = false}) =>
      hasStartingPrefix(prefix, ignoreCase: ignoreCase) ? this : prefix + this;

  /// Returns true if this string ends with [search].
  /// If [ignoreCase] is true, the comparison is case-insensitive.
  bool hasEndingSuffix(String search, {bool ignoreCase = false}) => ignoreCase
      ? toLowerCase().endsWith(search.toLowerCase())
      : endsWith(search);

  /// Removes [suffix] from the end of this string if present.
  /// If [ignoreCase] is true, the comparison is case-insensitive.
  /// Returns the original string if [suffix] is not found at the end.
  String tryRemoveSuffix(String suffix, {bool ignoreCase = false}) =>
      hasEndingSuffix(suffix, ignoreCase: ignoreCase)
          ? substring(0, length - suffix.length)
          : this;
}
