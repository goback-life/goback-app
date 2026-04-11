/// Model for link preview metadata.
///
/// This model represents metadata extracted from a URL for display
/// as a preview card (like Twitter/X link previews).
///
/// **Future Implementation:**
/// This structure is created now for future compatibility when link
/// preview fetching is implemented.
///
/// Note: This is a simple class for now. When link previews are fully
/// implemented, this can be converted to a freezed model.
class LinkPreviewModel {
  const LinkPreviewModel({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
}
