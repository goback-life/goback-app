import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class CalendarPostDtoToModelMapper
    extends DtoToModelMapperContract<CalendarPostDto, CalendarPostModel> {
  @override
  CalendarPostModel mapDto(CalendarPostDto dto) {
    final taggedUsernames =
        dto.taggedUsernames?.split(',').map((e) => e.trim()).toList() ?? [];
    final taggedUserIds =
        dto.taggedUserIds?.split(',').map((e) => e.trim()).toList() ?? [];

    final contentType = ContentType.values.firstWhere(
      (e) => e.name.toLowerCase() == dto.contentType.toLowerCase(),
      orElse: () => ContentType.image,
    );

    return CalendarPostModel(
      postId: dto.postId,
      authorId: dto.authorId,
      authorUsername: dto.authorUsername,
      authorAvatarUrl: dto.authorAvatarUrl,
      thumbnailUrl: dto.thumbnailUrl,
      thumbnailWidth: dto.thumbnailWidth,
      thumbnailHeight: dto.thumbnailHeight,
      description: dto.description,
      contentType: contentType,
      videoUrl: dto.videoUrl,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
      taggedUsernames: taggedUsernames,
      taggedUserIds: taggedUserIds,
      excludedUserIds: dto.excludedUserIds ?? [],
      isAuthorConnected: dto.isAuthorConnected,
      isOwnPost: dto.isOwnPost,
      publishedAt: DateTime.tryParse(dto.publishedAt) ?? DateTime.now(),
      publishedTimezone: dto.publishedTimezone,
      lockoutId: dto.lockoutId,
      calendarSavedAt: dto.calendarSavedAt != null
          ? DateTime.tryParse(dto.calendarSavedAt!)
          : null,
    );
  }
}
