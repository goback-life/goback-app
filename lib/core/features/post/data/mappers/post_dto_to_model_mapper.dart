import 'package:cloudless/core/features/post/data/dtos/post_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class PostDtoToModelMapper
    extends DtoToModelMapperContract<PostDto, PostModel> {
  @override
  PostModel mapDto(PostDto dto) {
    return PostModel(
      id: dto.id,
      authorId: dto.authorId,
      contentType: ContentType.values.firstWhere(
        (type) =>
            type.name.toLowerCase() ==
            dto.contentType.toLowerCase().replaceAll('_', ''),
        orElse: () => ContentType.image,
      ),
      thumbnailUrl: dto.thumbnailUrl,
      thumbnailWidth: dto.thumbnailWidth,
      thumbnailHeight: dto.thumbnailHeight,
      publishedAt: dto.publishedAt != null
          ? DateTime.parse(dto.publishedAt!)
          : DateTime.now(),
      description: dto.description,
      publishedTimezone: dto.publishedTimezone ?? 'UTC',
      status: PostStatus.published,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
      lockoutId: dto.lockoutId,
      calendarSavedAt: dto.calendarSavedAt != null
          ? DateTime.tryParse(dto.calendarSavedAt!)
          : null,
    );
  }
}
