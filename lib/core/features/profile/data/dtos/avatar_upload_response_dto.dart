// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'avatar_upload_response_dto.freezed.dart';
part 'avatar_upload_response_dto.g.dart';

@freezed
sealed class AvatarUploadResponseDto with _$AvatarUploadResponseDto {
  const factory AvatarUploadResponseDto({
    @JsonKey(name: 'public_url') required String publicUrl,
  }) = _AvatarUploadResponseDto;

  factory AvatarUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadResponseDtoFromJson(json);
}
