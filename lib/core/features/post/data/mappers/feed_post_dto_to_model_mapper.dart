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
    final taggedUsernames =
        dto.taggedUsernames?.split(',').map((e) => e.trim()).toList() ?? [];
    final taggedUserIds =
        dto.taggedUserIds?.split(',').map((e) => e.trim()).toList() ?? [];
    final excludedUserIds =
        dto.excludedUserIds?.split(',').map((e) => e.trim()).toList() ?? [];
    final parentExcludedUserIds =
        dto.parentExcludedUserIds?.split(',').map((e) => e.trim()).toList() ??
        [];

    final contentType = ContentType.values.firstWhere(
      (e) => e.name.toLowerCase() == dto.contentType.toLowerCase(),
      orElse: () => ContentType.image,
    );

    final parentContentType = dto.parentContentType != null
        ? ContentType.values.firstWhere(
            (e) => e.name.toLowerCase() == dto.parentContentType!.toLowerCase(),
            orElse: () => ContentType.image,
          )
        : null;

    return FeedPostModel(
      id: dto.id,
      authorId: dto.authorId,
      authorUsername: dto.authorUsername ?? 'Unknown User',
      imageUrl: dto.imageUrl ?? '',
      videoUrl: dto.videoUrl,
      thumbnailWidth: dto.thumbnailWidth,
      thumbnailHeight: dto.thumbnailHeight,
      contentDate: DateTime.tryParse(dto.contentDate) ?? DateTime.now(),
      publishedAt: DateTime.parse(dto.publishedAt),
      publishedTimezone: dto.publishedTimezone,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
      contentType: contentType,
      parentId: dto.parentId,
      parentAuthorId: dto.parentAuthorId,
      parentThumbnailUrl: dto.parentThumbnailUrl,
      parentAuthorUsername: dto.parentAuthorUsername,
      parentContentType: parentContentType,
      parentDeletedAt: dto.parentDeletedAt != null
          ? DateTime.tryParse(dto.parentDeletedAt!)
          : null,
      taggedUsernames: taggedUsernames,
      taggedUserIds: taggedUserIds,
      excludedUserIds: excludedUserIds,
      parentExcludedUserIds: parentExcludedUserIds,
      authorAvatarUrl: dto.authorAvatarUrl,
      description: dto.description,
      isAuthorConnected: dto.isAuthorConnected,
    );
  }

  List<FeedPostModel> mapDtoList(List<FeedPostDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
