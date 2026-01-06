/// Utility class for shortening URLs in text by converting them to markdown links
/// with the domain as the alias (e.g., https://youtube.com/watch?v=123 -> [youtube.com](https://youtube.com/watch?v=123))
class UrlShortener {
  UrlShortener._();

  /// Converts all URLs in the text to markdown links with domain aliases
  static String shortenUrlsInText(String text) {
    // Pattern to match URLs (http://, https://, or www.)
    final urlPattern = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+)',
      caseSensitive: false,
    );
    
    // Pattern to match existing markdown links (don't convert those)
    final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    
    // Get all markdown link ranges to exclude
    final markdownRanges = <({int start, int end})>[];
    for (final match in markdownLinkPattern.allMatches(text)) {
      markdownRanges.add((start: match.start, end: match.end));
    }
    
    String result = text;
    
    // Find all URLs and convert them to markdown links
    // Process in reverse to preserve positions
    final urlMatches = urlPattern.allMatches(text).toList();
    for (final match in urlMatches.reversed) {
      final urlStart = match.start;
      final urlEnd = match.end;
      
      // Check if this URL is inside a markdown link
      final isInMarkdown = markdownRanges.any((range) =>
          urlStart >= range.start && urlEnd <= range.end);
      
      if (isInMarkdown) continue;
      
      // Extract the URL
      final url = match.group(0)!;
      
      // Extract domain from URL
      final domain = _extractDomain(url);
      
      // Convert to markdown link [domain](url)
      final markdownLink = '[$domain]($url)';
      
      // Replace URL with markdown link
      result = result.replaceRange(urlStart, urlEnd, markdownLink);
    }
    
    return result;
  }
  
  /// Extract domain from URL
  static String _extractDomain(String url) {
    try {
      // Remove protocol
      String urlWithoutProtocol = url;
      if (url.startsWith('http://')) {
        urlWithoutProtocol = url.substring(7);
      } else if (url.startsWith('https://')) {
        urlWithoutProtocol = url.substring(8);
      } else if (url.startsWith('www.')) {
        urlWithoutProtocol = url.substring(4);
      }
      
      // Extract domain (everything before first /, ?, #, or space)
      final domainEnd = urlWithoutProtocol.indexOf(RegExp(r'[/?#\s]'));
      if (domainEnd != -1) {
        return urlWithoutProtocol.substring(0, domainEnd);
      }
      
      return urlWithoutProtocol;
    } catch (e) {
      // If extraction fails, return a simplified version
      return url.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'^www\.'), '');
    }
  }
}

