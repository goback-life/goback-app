// ignore_for_file: invalid_annotation_target
import 'package:cloudless/core/features/connection/data/dtos/profile_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'invite_code_dto.freezed.dart';
part 'invite_code_dto.g.dart';

@freezed
sealed class InviteCodeDto with _$InviteCodeDto {
  const factory InviteCodeDto({
    required String id,
    required String code,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'expires_at') required String expiresAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'used_by_id') String? usedById,
    ProfileDto? profiles,
  }) = _InviteCodeDto;

  factory InviteCodeDto.fromJson(Map<String, dynamic> json) =>
      _$InviteCodeDtoFromJson(json);
}
