import 'package:cloudless/core/features/lockout/data/dtos/lockout_session_dto.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

/// Maps LockoutSessionDto to LockoutSessionModel.
class LockoutSessionDtoToModelMapper
    extends DtoToModelMapperContract<LockoutSessionDto, LockoutSessionModel> {
  @override
  LockoutSessionModel mapDto(LockoutSessionDto dto) {
    return LockoutSessionModel(
      id: dto.id,
      userId: dto.userId,
      startedAt: DateTime.parse(dto.startedAt),
      endsAt: DateTime.parse(dto.endsAt),
      actionText: dto.actionText,
      locationLat: dto.locationLat,
      locationLng: dto.locationLng,
      locationName: dto.locationName,
      postId: dto.postId,
      createdAt: dto.createdAt != null
          ? DateTime.parse(dto.createdAt!)
          : DateTime.parse(dto.startedAt), // Fallback to startedAt
      participants: dto.participants,
      username: dto.username,
      avatarUrl: dto.avatarUrl,
    );
  }

  List<LockoutSessionModel> mapDtoList(List<LockoutSessionDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
