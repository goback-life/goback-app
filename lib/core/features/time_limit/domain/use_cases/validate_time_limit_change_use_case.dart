import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Validates if the time limit can be changed based on current usage
class ValidateTimeLimitChangeUseCase implements UseCaseContract<bool> {
  const ValidateTimeLimitChangeUseCase({
    required this.usageStorable,
    required this.newLimit,
  });

  final TimeLimitUsageStorable usageStorable;
  final int newLimit;

  @override
  Future<bool> execute() async {
    final usedMinutes = await usageStorable.getUsedMinutes();

    // Cannot decrease limit if already exceeded the new limit
    return newLimit >= usedMinutes;
  }
}
