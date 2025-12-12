import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Increments the used minutes by 1
class IncrementUsedMinutesUseCase implements UseCaseContract<void> {
  const IncrementUsedMinutesUseCase({required this.usageStorable});

  final TimeLimitUsageStorable usageStorable;

  @override
  Future<void> execute() async {
    await usageStorable.incrementUsedMinutes();
  }
}
