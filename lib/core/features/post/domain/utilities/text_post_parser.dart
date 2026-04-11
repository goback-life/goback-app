import 'package:cloudless/core/models/profile_model.dart';

/// Utility class for parsing text posts to extract mentions, markdown links, and URLs.
class TextPostParser {
  TextPostParser._();

  /// Regex pattern to match @username mentions
  /// Matches @ followed by alphanumeric characters and underscores
  static final RegExp _mentionPattern = RegExp(r'@(\w+)');

  /// Regex pattern to match markdown links [alias](url)
  static final RegExp _markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

  /// Regex pattern to match URLs (http://, https://, www.)
  static final RegExp _urlPattern = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+)',
    caseSensitive: false,
  );

  /// Extract @username patterns from text and return list of user IDs
  /// that match users in the provided list.
  static List<String> parseMentions(String text, List<ProfileModel> allUsers) {
    final mentions = <String>[];
    final usernameToId = <String, String>{};

    // Create a map of username (lowercase) to user ID
    for (final user in allUsers) {
      usernameToId[user.username.toLowerCase()] = user.id;
    }

    // Find all @username patterns
    for (final match in _mentionPattern.allMatches(text)) {
      final username = match.group(1)?.toLowerCase();
      if (username != null && usernameToId.containsKey(username)) {
        final userId = usernameToId[username]!;
        if (!mentions.contains(userId)) {
          mentions.add(userId);
        }
      }
    }

    return mentions;
  }

  /// Extract markdown link patterns [alias](url) from text
  /// Returns a list of tuples (alias, url)
  static List<({String alias, String url})> parseMarkdownLinks(String text) {
    final links = <({String alias, String url})>[];

    for (final match in _markdownLinkPattern.allMatches(text)) {
      final alias = match.group(1);
      final url = match.group(2);
      if (alias != null && url != null) {
        links.add((alias: alias, url: url));
      }
    }

    return links;
  }

  /// Check if text contains URLs (not already in markdown format)
  static bool hasUrl(String text) {
    // First check if there are any markdown links
    final markdownLinks = parseMarkdownLinks(text);
    if (markdownLinks.isNotEmpty) {
      return false; // URLs are already in markdown format
    }

    // Check for regular URLs
    return _urlPattern.hasMatch(text);
  }

  /// Find all URLs in text that are not already in markdown format
  /// Returns list of URLs with their positions
  static List<({String url, int start, int end})> findUrls(String text) {
    final urls = <({String url, int start, int end})>[];

    // Get all markdown link positions to exclude them
    final markdownRanges = <({int start, int end})>[];
    for (final match in _markdownLinkPattern.allMatches(text)) {
      markdownRanges.add((start: match.start, end: match.end));
    }

    // Find all URLs
    for (final match in _urlPattern.allMatches(text)) {
      final url = match.group(0)!;
      final start = match.start;
      final end = match.end;

      // Check if this URL is inside a markdown link
      final isInMarkdown = markdownRanges.any(
        (range) => start >= range.start && end <= range.end,
      );

      if (!isInMarkdown) {
        urls.add((url: url, start: start, end: end));
      }
    }

    return urls;
  }

  /// Convert URL to markdown format [alias](url)
  static String convertUrlToMarkdown(String url, String alias) {
    return '[$alias]($url)';
  }

  /// Replace a URL in text with markdown format
  /// Returns the new text with the URL replaced
  static String replaceUrlWithMarkdown(
    String text,
    String originalUrl,
    String alias,
  ) {
    final markdownLink = convertUrlToMarkdown(originalUrl, alias);
    return text.replaceFirst(originalUrl, markdownLink);
  }
}
