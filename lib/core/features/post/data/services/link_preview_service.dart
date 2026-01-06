/// Service for fetching link preview metadata from URLs.
/// 
/// **Future Implementation:**
/// This service interface is structured now for future compatibility.
/// When implemented, it will fetch metadata (title, description, image, etc.)
/// from URLs to display as preview cards.
/// 
/// **Recommended Implementation:**
/// - Use Supabase Edge Function for server-side fetching
/// - Cache previews to avoid re-fetching same URLs
/// - Handle errors gracefully (show link without preview if fetch fails)
class LinkPreviewService {
  const LinkPreviewService();

  /// Fetches link preview metadata for a given URL.
  /// 
  /// Returns null if fetching fails or is not yet implemented.
  Future<Map<String, dynamic>?> fetchLinkPreview(String url) async {
    // TODO: Implement link preview fetching
    // This will be implemented when link preview feature is added
    return null;
  }

  /// Fetches link previews for multiple URLs.
  /// 
  /// Returns a map of URL to preview data (or null if fetch failed).
  Future<Map<String, Map<String, dynamic>?>> fetchLinkPreviews(
    List<String> urls,
  ) async {
    // TODO: Implement batch link preview fetching
    // This will be implemented when link preview feature is added
    return {for (final url in urls) url: null};
  }
}

