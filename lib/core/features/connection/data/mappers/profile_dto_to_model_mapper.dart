import 'package:cloudless/core/features/connection/data/dtos/profile_dto.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';
import 'package:cloudless/core/models/profile_model.dart';

class ProfileDtoToModelMapper
    extends DtoToModelMapperContract<ProfileDto, ProfileModel> {
  @override
  ProfileModel mapDto(ProfileDto dto) {
    return ProfileModel(
      id: dto.id,
      username: dto.username,
      biography: dto.biography,
      avatarUrl: dto.avatarUrl,
      phoneNumber: dto.phoneNumber,
    );
  }
}
