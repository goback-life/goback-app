// ignore_for_file: invalid_annotation_target
import 'package:cloudless/core/features/connection/data/dtos/profile_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'connection_dto.freezed.dart';
part 'connection_dto.g.dart';

@freezed
sealed class ConnectionDto with _$ConnectionDto {
  const factory ConnectionDto({
    @JsonKey(name: 'friendship_id') required String connectionId,
    ProfileDto? profiles,
  }) = _ConnectionDto;

  factory ConnectionDto.fromJson(Map<String, dynamic> json) =>
      _$ConnectionDtoFromJson(json);
}
