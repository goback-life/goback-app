import 'package:cloudless/core/features/post/data/dtos/feed_post_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';

/// Mapper that converts [FeedPostDto] to [FeedPostModel].
///
/// **Timezone Handling:**
/// The `createdAt` and `updatedAt` timestamps from the DTO are in ISO 8601 format
/// with UTC timezone. When parsed with [DateTime.tryParse], the resulting DateTime
/// objects represent the UTC time. The conversion to the user's local timezone
/// happens later when these timestamps are formatted for display in the UI.
class FeedPostDtoToModelMapper {
  FeedPostModel mapDto(FeedPostDto dto) {
    // Arrays come directly from database RPC
    final taggedUsernames = dto.taggedUsernames ?? [];
    final taggedUserIds = dto.taggedUserIds ?? [];
    final excludedUserIds = dto.excludedUserIds ?? [];

    final contentType = ContentType.values.firstWhere(
      (e) => e.name.toLowerCase() == dto.contentType.toLowerCase(),
      orElse: () => ContentType.image,
    );

    return FeedPostModel(
      id: dto.id,
      authorId: dto.authorId,
      authorUsername: dto.authorUsername ?? 'Unknown User',
      imageUrl: dto.imageUrl ?? '',
      videoUrl: dto.videoUrl,
      thumbnailWidth: dto.thumbnailWidth,
      thumbnailHeight: dto.thumbnailHeight,
      publishedAt: DateTime.parse(dto.publishedAt),
      publishedTimezone: dto.publishedTimezone,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
      contentType: contentType,
      taggedUsernames: taggedUsernames,
      taggedUserIds: taggedUserIds,
      excludedUserIds: excludedUserIds,
      authorAvatarUrl: dto.authorAvatarUrl,
      description: dto.description,
      isAuthorConnected: dto.isAuthorConnected ?? false,
      lockoutId: dto.lockoutId,
      lockoutScore: dto.lockoutScore,
      lockoutDurationMinutes: dto.lockoutDurationMinutes,
      calendarSavedAt: dto.calendarSavedAt != null
          ? DateTime.tryParse(dto.calendarSavedAt!)
          : null,
      linkPreviews: [], // TODO: Parse linkPreviews JSON when implemented
      reactionCount: dto.reactionCount ?? 0,
      commentCount: dto.commentCount ?? 0,
    );
  }

  List<FeedPostModel> mapDtoList(List<FeedPostDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
