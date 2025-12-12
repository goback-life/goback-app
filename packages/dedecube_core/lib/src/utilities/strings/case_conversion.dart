extension CaseConversion on String {
  /// Regular expression to split words based on uppercase letters
  static final _pascalWordsRE =
      RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])');

  /// Splits a string into a list of words based on uppercase letters
  List<String> get splitWordsFromUppercase => split(_pascalWordsRE);

  /// Converts a variable name to spaced pascal case
  ///
  /// Example: "myVariableName" becomes "My Variable Name"
  String get variableNameToSpacedPascalCase {
    if (isEmpty) {
      return '';
    }
    final list = splitWordsFromUppercase;
    if (list.isEmpty) {
      return '';
    }
    return [
      for (final word in list) word.capitalizeFirst,
    ].join(' ');
  }

  /// Capitalizes the first letter of the string and converts the rest to lowercase
  ///
  /// Example: "hELLo" becomes "Hello"
  String get capitalizeFirst {
    if (isEmpty) {
      return '';
    }
    if (length == 1) {
      return toUpperCase();
    }
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Capitalizes the first letter of each word in the string
  ///
  /// Example: "hello world" becomes "Hello World"
  String get capitalizeFirstOfEachWord {
    if (isEmpty) {
      return '';
    }
    final list = split(' ');
    if (list.isEmpty) {
      return '';
    }
    return [
      for (final word in list) word.capitalizeFirst,
    ].join(' ');
  }
}
