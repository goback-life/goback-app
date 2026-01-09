/// Constants for text post configuration
class TextPostConstants {
  TextPostConstants._();

  /// Maximum character limit for text posts
  /// This matches the database constraint: char_length(description) <= 500
  static const int maxTextPostLength = 500;
}

