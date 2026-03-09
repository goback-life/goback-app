import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_monthly_summary_dto.freezed.dart';
part 'lockout_monthly_summary_dto.g.dart';

@freezed
sealed class LockoutMonthlySummaryDto with _$LockoutMonthlySummaryDto {
  const factory LockoutMonthlySummaryDto({
    @JsonKey(name: 'total_minutes') required int totalMinutes,
    @JsonKey(name: 'avg_score') double? avgScore,
    @JsonKey(name: 'session_count') required int sessionCount,
    @JsonKey(name: 'max_duration_minutes') required int maxDurationMinutes,
  }) = _LockoutMonthlySummaryDto;

  factory LockoutMonthlySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutMonthlySummaryDtoFromJson(json);
}
