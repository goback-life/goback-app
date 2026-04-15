// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_participant_dto.freezed.dart';
part 'lockout_participant_dto.g.dart';

@freezed
sealed class LockoutParticipantDto with _$LockoutParticipantDto {
  const factory LockoutParticipantDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'joined_via') String? joinedVia,
    @JsonKey(name: 'joined_at') required String joinedAt,
    @JsonKey(name: 'left_at') String? leftAt,
    @JsonKey(name: 'goback_score') int? gobackScore,
    String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _LockoutParticipantDto;

  factory LockoutParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutParticipantDtoFromJson(json);
}
