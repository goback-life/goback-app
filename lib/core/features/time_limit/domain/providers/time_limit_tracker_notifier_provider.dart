import 'dart:async';

import 'package:cloudless/core/config/time_limit_values.dart';
import 'package:cloudless/core/features/time_limit/data/providers/time_limit_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/data/providers/time_limit_usage_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/check_new_day_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/get_time_limit_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/increment_used_minutes_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/reset_daily_usage_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/set_time_limit_use_case.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/validate_time_limit_change_use_case.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_limit_tracker_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class TimeLimitTrackerNotifier extends _$TimeLimitTrackerNotifier {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTracking = false;

  @override
  Future<TimeLimitModel> build() async {
    // Register cleanup callback
    ref.onDispose(() {
      logger.info('Disposing time limit tracker - stopping tracking');
      stopTracking();
    });

    // Check if it's a new day and reset if needed
    await _checkAndResetIfNewDay();

    // Load current state
    final useCase = GetTimeLimitUseCase(
      storable: ref.watch(timeLimitStorableProvider),
      usageStorable: ref.watch(timeLimitUsageStorableProvider),
    );

    final model = await useCase.execute();

    // Start tracking if limit not reached
    if (!model.isLimitReached) {
      startTracking();
    }

    return model;
  }

  Future<void> _checkAndResetIfNewDay() async {
    final checkNewDayUseCase = CheckNewDayUseCase(
      usageStorable: ref.read(timeLimitUsageStorableProvider),
    );

    final isNewDay = await checkNewDayUseCase.execute();
    if (isNewDay) {
      logger.info('New day detected - resetting time limit usage');
      final resetUseCase = ResetDailyUsageUseCase(
        usageStorable: ref.read(timeLimitUsageStorableProvider),
      );
      await resetUseCase.execute();
    }
  }

  void startTracking() {
    if (_isTracking) {
      return;
    }

    logger.info('Starting time limit tracking');
    _isTracking = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void stopTracking() {
    if (!_isTracking) {
      return;
    }

    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _secondsElapsed = 0;
  }

  void _onTick() {
    _secondsElapsed++;

    // Every 60 seconds, increment a minute
    if (_secondsElapsed >= 60) {
      _secondsElapsed = 0;
      _incrementMinute();
    }
  }

  Future<void> _incrementMinute() async {
    final incrementUseCase = IncrementUsedMinutesUseCase(
      usageStorable: ref.read(timeLimitUsageStorableProvider),
    );

    await incrementUseCase.execute();

    // Reload the state
    final getUseCase = GetTimeLimitUseCase(
      storable: ref.read(timeLimitStorableProvider),
      usageStorable: ref.read(timeLimitUsageStorableProvider),
    );

    final updatedModel = await getUseCase.execute();
    state = AsyncValue.data(updatedModel);

    logger.info(
      'Time limit: ${updatedModel.usedMinutes}/${updatedModel.minutes} minutes',
    );

    // Stop tracking if limit reached
    if (updatedModel.isLimitReached) {
      logger.info('Time limit reached - stopping tracking');
      stopTracking();
    }
  }

  Future<bool> setTimeLimit(int minutes) async {
    // Validate the change
    final validateUseCase = ValidateTimeLimitChangeUseCase(
      usageStorable: ref.read(timeLimitUsageStorableProvider),
      newLimit: minutes,
    );

    final canChange = await validateUseCase.execute();
    if (!canChange) {
      logger.warning('Cannot decrease time limit below current usage');
      return false;
    }

    // Update the limit
    final setUseCase = SetTimeLimitUseCase(
      storable: ref.read(timeLimitStorableProvider),
      usageStorable: ref.read(timeLimitUsageStorableProvider),
      minutes: minutes,
    );

    state = const AsyncValue.loading();
    try {
      final result = await setUseCase.execute();
      state = AsyncValue.data(result);
      logger.info('Time limit updated to $minutes minutes');
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

  Future<void> checkAndResetIfNewDay() async {
    await _checkAndResetIfNewDay();

    // Reload state after potential reset
    final getUseCase = GetTimeLimitUseCase(
      storable: ref.read(timeLimitStorableProvider),
      usageStorable: ref.read(timeLimitUsageStorableProvider),
    );

    final updatedModel = await getUseCase.execute();
    state = AsyncValue.data(updatedModel);

    // Restart tracking if limit not reached
    if (!updatedModel.isLimitReached && !_isTracking) {
      startTracking();
    }
  }
}
