import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/manual_lockout_model.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/check_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/clear_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/get_lockout_remaining_time_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/set_manual_lockout_use_case.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_lockout_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class ManualLockoutNotifier extends _$ManualLockoutNotifier {
  @override
  Future<ManualLockoutModel> build() async {
    final storable = ref.watch(manualLockoutStorableProvider);
    final checkUseCase = CheckManualLockoutUseCase(storable: storable);
    final isLockedOut = await checkUseCase.execute();

    Duration? remainingDuration;
    if (isLockedOut) {
      final getRemainingUseCase = GetLockoutRemainingTimeUseCase(
        storable: storable,
      );
      remainingDuration = await getRemainingUseCase.execute();
    }

    return ManualLockoutModel(
      isLockedOut: isLockedOut && remainingDuration != null,
      remainingDuration: remainingDuration,
    );
  }

  Future<void> setLockout(Duration duration) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final useCase = SetManualLockoutUseCase(
      storable: storable,
      duration: duration,
    );

    state = const AsyncValue.loading();
    try {
      await useCase.execute();

      // Reload state
      final checkUseCase = CheckManualLockoutUseCase(storable: storable);
      final isLockedOut = await checkUseCase.execute();

      Duration? remainingDuration;
      if (isLockedOut) {
        final getRemainingUseCase = GetLockoutRemainingTimeUseCase(
          storable: storable,
        );
        remainingDuration = await getRemainingUseCase.execute();
      }

      state = AsyncValue.data(
        ManualLockoutModel(
          isLockedOut: isLockedOut && remainingDuration != null,
          remainingDuration: remainingDuration,
        ),
      );

      logger.info('Manual lockout set for ${duration.inHours} hours');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error(
        'Error setting manual lockout',
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearLockout() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final useCase = ClearManualLockoutUseCase(storable: storable);

    state = const AsyncValue.loading();
    try {
      await useCase.execute();
      state = AsyncValue.data(
        const ManualLockoutModel(isLockedOut: false),
      );
      logger.info('Manual lockout cleared');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error(
        'Error clearing manual lockout',
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Duration?> getRemainingTime() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final useCase = GetLockoutRemainingTimeUseCase(storable: storable);
    return await useCase.execute();
  }

  Future<void> refresh() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final checkUseCase = CheckManualLockoutUseCase(storable: storable);
    final isLockedOut = await checkUseCase.execute();

    Duration? remainingDuration;
    if (isLockedOut) {
      final getRemainingUseCase = GetLockoutRemainingTimeUseCase(
        storable: storable,
      );
      remainingDuration = await getRemainingUseCase.execute();
    }

    state = AsyncValue.data(
      ManualLockoutModel(
        isLockedOut: isLockedOut && remainingDuration != null,
        remainingDuration: remainingDuration,
      ),
    );
  }
}

