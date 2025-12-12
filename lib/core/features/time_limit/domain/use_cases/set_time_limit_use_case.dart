import 'package:cloudless/core/features/time_limit/data/storables/time_limit_storable.dart';
import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class SetTimeLimitUseCase implements UseCaseContract<TimeLimitModel> {
  const SetTimeLimitUseCase({
    required this.storable,
    required this.usageStorable,
    required this.minutes,
  });

  final TimeLimitStorable storable;
  final TimeLimitUsageStorable usageStorable;
  final int minutes;

  @override
  Future<TimeLimitModel> execute() async {
    await storable.setTimeLimit(minutes);
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
