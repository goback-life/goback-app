import 'package:cloudless/core/features/post/data/dtos/post_reaction_dto.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class PostReactionDtoToModelMapper
    extends DtoToModelMapperContract<PostReactionDto, PostReactionModel> {
  @override
  PostReactionModel mapDto(PostReactionDto dto) {
    return PostReactionModel(
      id: dto.id,
      postId: dto.postId,
      userId: dto.userId,
      reaction: dto.reaction,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
    );
  }
}
