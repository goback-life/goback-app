import 'package:cloudless/core/config/time_limit_values.dart';
import 'package:cloudless/core/features/time_limit/data/providers/time_limit_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/data/providers/time_limit_usage_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/get_time_limit_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/set_time_limit_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/validate_time_limit_change_use_case.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_limit_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class TimeLimitNotifier extends _$TimeLimitNotifier {
  @override
  Future<TimeLimitModel> build() async {
    final useCase = GetTimeLimitUseCase(
      storable: ref.watch(timeLimitStorableProvider),
      usageStorable: ref.watch(timeLimitUsageStorableProvider),
    );
    return useCase.execute();
  }

  Future<bool> setTimeLimit(int minutes) async {
    // Validate the change first
    final validateUseCase = ValidateTimeLimitChangeUseCase(
      usageStorable: ref.read(timeLimitUsageStorableProvider),
      newLimit: minutes,
    );

    final canChange = await validateUseCase.execute();
    if (!canChange) {
      logger.warning('Cannot decrease time limit below current usage');
      return false;
    }

    final useCase = SetTimeLimitUseCase(
      storable: ref.read(timeLimitStorableProvider),
      usageStorable: ref.read(timeLimitUsageStorableProvider),
      minutes: minutes,
    );

    state = const AsyncValue.loading();
    try {
      final result = await useCase.execute();
      state = AsyncValue.data(result);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> toggleTimeLimit() async {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final newMinutes =
          currentState.minutes == TimeLimitValues.getShortMinutes()
          ? TimeLimitValues.getLongMinutes()
          : TimeLimitValues.getShortMinutes();
      return await setTimeLimit(newMinutes);
    }
    return false;
  }
}
