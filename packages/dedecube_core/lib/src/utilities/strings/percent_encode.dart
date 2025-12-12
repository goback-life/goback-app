extension PercentEncode on String {
  /// quick getter to the percent-encoded string to use in the body of a url for certain APIs
  String get percentEncoded => Uri.encodeQueryComponent(this);
}
