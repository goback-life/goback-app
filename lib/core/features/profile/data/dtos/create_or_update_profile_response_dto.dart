// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'create_or_update_profile_response_dto.freezed.dart';
part 'create_or_update_profile_response_dto.g.dart';

@freezed
sealed class CreateOrUpdateProfileResponseDto
    with _$CreateOrUpdateProfileResponseDto {
  const factory CreateOrUpdateProfileResponseDto({
    required String id,
    required String username,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? biography,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'phone_number') String? phoneNumber,
  }) = _CreateOrUpdateProfileResponseDto;

  factory CreateOrUpdateProfileResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$CreateOrUpdateProfileResponseDtoFromJson(json);
}
