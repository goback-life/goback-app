import 'package:cloudless/core/features/profile/data/dtos/get_profile_response_dto.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';
import 'package:cloudless/core/models/profile_model.dart';

class GetProfileResponseDtoToModelMapper
    extends DtoToModelMapperContract<GetProfileResponseDto, ProfileModel> {
  @override
  ProfileModel mapDto(GetProfileResponseDto dto) {
    return ProfileModel(
      id: dto.id,
      username: dto.username,
      biography: dto.biography,
      avatarUrl: dto.avatarUrl,
      phoneNumber: dto.phoneNumber,
    );
  }
}
