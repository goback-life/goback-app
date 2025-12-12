import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Resets the usage data (used minutes and date) to start a new day
class ResetDailyUsageUseCase implements UseCaseContract<void> {
  const ResetDailyUsageUseCase({required this.usageStorable});

  final TimeLimitUsageStorable usageStorable;

  @override
  Future<void> execute() async {
    await usageStorable.resetUsage();
  }
}
