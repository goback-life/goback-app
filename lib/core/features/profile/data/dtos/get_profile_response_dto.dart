// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'get_profile_response_dto.freezed.dart';
part 'get_profile_response_dto.g.dart';

@freezed
sealed class GetProfileResponseDto with _$GetProfileResponseDto {
  const factory GetProfileResponseDto({
    required String id,
    required String username,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? biography,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'phone_number') String? phoneNumber,
  }) = _GetProfileResponseDto;

  factory GetProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetProfileResponseDtoFromJson(json);
}
