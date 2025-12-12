// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

@freezed
sealed class ProfileDto with _$ProfileDto {
  const factory ProfileDto({
    required String id,
    required String username,
    String? biography,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'phone_number') String? phoneNumber,
  }) = _ProfileDto;

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);
}
