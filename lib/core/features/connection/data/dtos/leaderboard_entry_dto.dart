// ignore_for_file: invalid_annotation_target
import 'package:dedecube_core/dedecube_core.dart';

part 'leaderboard_entry_dto.freezed.dart';
part 'leaderboard_entry_dto.g.dart';

@freezed
sealed class LeaderboardEntryDto with _$LeaderboardEntryDto {
  const factory LeaderboardEntryDto({
    @JsonKey(name: 'user_id') required String userId,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'avg_duration_minutes') double? avgDurationMinutes,
    @JsonKey(name: 'session_count') @Default(0) int sessionCount,
    @JsonKey(name: 'is_current_user') @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntryDto;

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryDtoFromJson(json);
}
