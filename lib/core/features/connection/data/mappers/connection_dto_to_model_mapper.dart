import 'package:cloudless/core/features/connection/data/dtos/connection_dto.dart';
import 'package:cloudless/core/features/connection/data/mappers/profile_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class ConnectionDtoToModelMapper
    extends DtoToModelMapperContract<ConnectionDto, ConnectionMemberModel> {
  final ProfileDtoToModelMapper _profileMapper = ProfileDtoToModelMapper();

  @override
  ConnectionMemberModel mapDto(ConnectionDto dto) {
    if (dto.profiles == null) {
      throw ArgumentError('Profile data is required for connection mapping');
    }

    final profile = _profileMapper.mapDto(dto.profiles!);
    return ConnectionMemberModel(
      friendshipId: dto.connectionId,
      profile: profile,
    );
  }
}
