import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';

class CalendarPostDtoToModelMapper {
  CalendarPostModel mapDto(CalendarPostDto dto) {
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

    return CalendarPostModel(
      calendarId: dto.calendarId,
      calendarDate: DateTime.tryParse(dto.calendarDate) ?? DateTime.now(),
      postId: dto.postId,
      authorId: dto.authorId,
      authorUsername: dto.authorUsername,
      authorAvatarUrl: dto.authorAvatarUrl,
      thumbnailUrl: dto.thumbnailUrl,
      thumbnailWidth: dto.thumbnailWidth,
      thumbnailHeight: dto.thumbnailHeight,
      contentDate: DateTime.tryParse(dto.contentDate) ?? DateTime.now(),
      description: dto.description,
      contentType: contentType,
      videoUrl: dto.videoUrl,
      parentId: dto.parentId,
      parentAuthorId: dto.parentAuthorId,
      parentThumbnailUrl: dto.parentThumbnailUrl,
      parentAuthorUsername: dto.parentAuthorUsername,
      parentContentType: parentContentType,
      parentDeletedAt: dto.parentDeletedAt != null
          ? DateTime.tryParse(dto.parentDeletedAt!)
          : null,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
      taggedUsernames: taggedUsernames,
      taggedUserIds: taggedUserIds,
      excludedUserIds: excludedUserIds,
      parentExcludedUserIds: parentExcludedUserIds,
      isAuthorConnected: dto.isAuthorConnected,
      isOwnPost: dto.isOwnPost,
      isToday: dto.isToday,
      publishedAt: DateTime.tryParse(dto.publishedAt) ?? DateTime.now(),
      publishedTimezone: dto.publishedTimezone,
    );
  }

  List<CalendarPostModel> mapDtoList(List<CalendarPostDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
