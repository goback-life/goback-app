/// Lightweight DTO for the `get_pending_selection_posts` RPC response.
/// Plain class — no code generation required.
class PendingSelectionPostDto {
  const PendingSelectionPostDto({
    required this.id,
    required this.contentType,
    required this.publishedAt,
    this.thumbnailUrl,
    this.description,
  });

  factory PendingSelectionPostDto.fromJson(Map<String, dynamic> json) {
    return PendingSelectionPostDto(
      id: json['id'] as String,
      contentType: json['content_type'] as String,
      publishedAt: json['published_at'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String contentType;
  final String publishedAt;
  final String? thumbnailUrl;
  final String? description;
}
