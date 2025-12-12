// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'create_or_update_profile_request_dto.freezed.dart';
part 'create_or_update_profile_request_dto.g.dart';

@freezed
sealed class CreateOrUpdateProfileRequestDto
    with _$CreateOrUpdateProfileRequestDto {
  const factory CreateOrUpdateProfileRequestDto({
    required String id,
    required String username,
    String? biography,
  }) = _CreateOrUpdateProfileRequestDto;

  factory CreateOrUpdateProfileRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOrUpdateProfileRequestDtoFromJson(json);
}
