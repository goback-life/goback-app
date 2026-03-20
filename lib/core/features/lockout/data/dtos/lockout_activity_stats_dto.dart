import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_activity_stats_dto.freezed.dart';
part 'lockout_activity_stats_dto.g.dart';

@freezed
sealed class LockoutActivityStatsDto with _$LockoutActivityStatsDto {
  const factory LockoutActivityStatsDto({
    @JsonKey(name: 'action_text') required String actionText,
    @JsonKey(name: 'total_minutes') required int totalMinutes,
    @JsonKey(name: 'session_count') required int sessionCount,
  }) = _LockoutActivityStatsDto;

  factory LockoutActivityStatsDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutActivityStatsDtoFromJson(json);
}
