import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_daily_stats_dto.freezed.dart';
part 'lockout_daily_stats_dto.g.dart';

@freezed
sealed class LockoutDailyStatsDto with _$LockoutDailyStatsDto {
  const factory LockoutDailyStatsDto({
    required String day,
    required int minutes,
    @JsonKey(name: 'session_count') required int sessionCount,
    @JsonKey(name: 'avg_score') double? avgScore,
  }) = _LockoutDailyStatsDto;

  factory LockoutDailyStatsDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutDailyStatsDtoFromJson(json);
}
