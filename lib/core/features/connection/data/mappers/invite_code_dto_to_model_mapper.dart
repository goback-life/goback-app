import 'package:cloudless/core/features/connection/data/dtos/invite_code_dto.dart';
import 'package:cloudless/core/features/connection/data/mappers/profile_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_code_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class InviteCodeDtoToModelMapper
    extends DtoToModelMapperContract<InviteCodeDto, InviteCodeModel> {
  final ProfileDtoToModelMapper _profileMapper = ProfileDtoToModelMapper();

  @override
  InviteCodeModel mapDto(InviteCodeDto dto) {
    return InviteCodeModel(
      id: dto.id,
      code: dto.code,
      creatorId: dto.creatorId,
      usedById: dto.usedById,
      expiresAt: DateTime.parse(dto.expiresAt),
      createdAt: DateTime.parse(dto.createdAt),
      creatorProfile: dto.profiles != null
          ? _profileMapper.mapDto(dto.profiles!)
          : null,
    );
  }
}
