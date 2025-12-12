import 'package:cloudless/core/features/time_limit/data/storables/time_limit_storable.dart';
import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Gets the current time limit configuration with usage data
class GetTimeLimitWithUsageUseCase implements UseCaseContract<TimeLimitModel> {
  const GetTimeLimitWithUsageUseCase({
    required this.storable,
    required this.usageStorable,
  });

  final TimeLimitStorable storable;
  final TimeLimitUsageStorable usageStorable;

  @override
  Future<TimeLimitModel> execute() async {
    final minutes = await storable.getTimeLimit();
    final usedMinutes = await usageStorable.getUsedMinutes();
    final lastUsageDate = await usageStorable.getLastUsageDate();

    return TimeLimitModel(
      minutes: minutes,
      isActive: true,
      usedMinutes: usedMinutes,
      lastUsageDate: lastUsageDate,
    );
  }
}
