import 'package:cloudless/core/features/comment/data/dtos/post_comment_dto.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

/// Maps PostCommentDto to PostCommentModel.
class CommentDtoToModelMapper
    extends DtoToModelMapperContract<PostCommentDto, PostCommentModel> {
  @override
  PostCommentModel mapDto(PostCommentDto dto) {
    return PostCommentModel(
      id: dto.id,
      postId: dto.postId,
      authorId: dto.authorId,
      authorUsername: dto.authorUsername,
      authorAvatarUrl: dto.authorAvatarUrl,
      content: dto.content,
      createdAt: DateTime.parse(dto.createdAt),
      deletedAt: dto.deletedAt != null ? DateTime.parse(dto.deletedAt!) : null,
    );
  }

  List<PostCommentModel> mapDtoList(List<PostCommentDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
