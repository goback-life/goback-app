import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_notifier_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

class TimeLimitData {
  const TimeLimitData({
    required this.timeLimit,
    required this.isLoading,
    required this.toggleTimeLimit,
    required this.setTimeLimit,
    required this.canSetTimeLimit,
  });

  final TimeLimitModel? timeLimit;
  final bool isLoading;
  final Future<bool> Function() toggleTimeLimit;
  final Future<bool> Function(int) setTimeLimit;
  final Future<bool> Function(int) canSetTimeLimit;
}

TimeLimitData useTimeLimit(WidgetRef ref) {
  final timeLimitAsync = ref.watch(timeLimitNotifierProvider);
  final notifier = ref.read(timeLimitNotifierProvider.notifier);

  return TimeLimitData(
    timeLimit: timeLimitAsync.valueOrNull,
    isLoading: timeLimitAsync.isLoading,
    toggleTimeLimit: notifier.toggleTimeLimit,
    setTimeLimit: notifier.setTimeLimit,
    canSetTimeLimit: (minutes) async {
      // This is used to pre-validate without actually changing
      final currentMinutes = timeLimitAsync.valueOrNull?.usedMinutes ?? 0;
      return minutes >= currentMinutes;
    },
  );
}
