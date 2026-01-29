// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'get_circle_members_response_dto.freezed.dart';
part 'get_circle_members_response_dto.g.dart';

@freezed
sealed class GetCircleMembersResponseDto with _$GetCircleMembersResponseDto {
  const factory GetCircleMembersResponseDto({
    @JsonKey(name: 'friendship_id') required String friendshipId,
    required String id,
    required String username,
    String? biography,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'phone_number') String? phoneNumber,
  }) = _GetCircleMembersResponseDto;

  factory GetCircleMembersResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetCircleMembersResponseDtoFromJson(json);
}