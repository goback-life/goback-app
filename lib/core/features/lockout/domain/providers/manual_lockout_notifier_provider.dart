import 'package:battery_plus/battery_plus.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/manual_lockout_model.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/check_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/clear_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/get_lockout_remaining_time_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/join_lockout_use_case.dart';
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

  /// Sets a lockout for the given duration.
  ///
  /// Creates a lockout session in the database and stores locally.
  /// Returns the session ID for use when creating a lockout post.
  Future<String?> setLockout(
    Duration duration, {
    String? actionText,
    double? locationLat,
    double? locationLng,
    String? locationName,
  }) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final sessionService = ref.read(lockoutSessionServiceProvider);
    state = const AsyncValue.loading();
    String? sessionId;

    // Capture battery level at lockout start
    int? batteryAtStart;
    try {
      batteryAtStart = await Battery().batteryLevel;
    } catch (_) {
      // Permission denied or unavailable - score will be null
    }

    try {
      // Create session in database first
      final sessionResult = await sessionService.createSession(
        duration: duration,
        actionText: actionText,
        locationLat: locationLat,
        locationLng: locationLng,
        locationName: locationName,
      );

      sessionResult.fold(
        (session) {
          sessionId = session.id;
          logger.info('Lockout session created with ID: $sessionId');
        },
        (error) => logger.warning('Failed to create DB session: $error'),
      );

      // Store locally with session ID for post creation after lockout ends
      logger.info('Storing lockout locally with sessionId: $sessionId');
      final useCase = SetManualLockoutUseCase(
        storable: storable,
        duration: duration,
        sessionId: sessionId,
        batteryAtStart: batteryAtStart,
      );
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
      return sessionId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error(
        'Error setting manual lockout',
        exception: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Dismisses the completion UI without clearing local storage.
  /// Used by _handleShare so lockoutStartTimestamp remains available
  /// for the post-creation hook to read later.
  void dismissCompletion() {
    state = AsyncValue.data(
      const ManualLockoutModel(
        isLockedOut: false,
        isCompletionPending: false,
      ),
    );
  }

  Future<void> clearLockout() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final useCase = ClearManualLockoutUseCase(storable: storable);

    state = const AsyncValue.loading();
    try {
      await useCase.execute();
      state = AsyncValue.data(
        const ManualLockoutModel(
          isLockedOut: false,
          isCompletionPending: false,
        ),
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

  /// Joins an existing lockout session by session ID.
  ///
  /// Calls the database RPC to join and stores locally.
  Future<void> joinLockout(String lockoutSessionId) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final sessionService = ref.read(lockoutSessionServiceProvider);

    // Capture battery level at lockout start
    int? batteryAtStart;
    try {
      batteryAtStart = await Battery().batteryLevel;
    } catch (_) {
      // Permission denied or unavailable - score will be null
    }

    state = const AsyncValue.loading();
    try {
      // Get session details to determine end time
      final sessionResult = await sessionService.getSessionById(lockoutSessionId);
      DateTime? lockoutEndTime;
      Exception? sessionError;

      await sessionResult.asyncFold(
        (session) async {
          if (session != null) {
            lockoutEndTime = DateTime.parse(session.endsAt);
            // Join session in database - check result for RPC errors
            final joinResult = await sessionService.joinSession(
              sessionId: lockoutSessionId,
            );
            joinResult.fold(
              (_) {},
              (error) {
                sessionError = error;
              },
            );
          }
        },
        (error) async {
          logger.warning('Failed to get session: $error');
          sessionError = error;
        },
      );

      // Throw any error from the RPC (e.g., "already in an active lockout")
      if (sessionError != null) {
        throw sessionError!;
      }

      if (lockoutEndTime == null) {
        throw Exception('Could not get lockout session end time');
      }

      // Store locally with session ID for same-lockout detection
      final useCase = JoinLockoutUseCase(
        storable: storable,
        lockoutEndTime: lockoutEndTime!,
        lockoutSessionId: lockoutSessionId,
        batteryAtStart: batteryAtStart,
      );
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

      logger.info('Joined lockout session $lockoutSessionId');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error(
        'Error joining lockout',
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final checkUseCase = CheckManualLockoutUseCase(storable: storable);
    final isLockedOut = await checkUseCase.execute();

    final wasLockedOut = state.value?.isLockedOut ?? false;
    final wasCompletionPending = state.value?.isCompletionPending ?? false;

    Duration? remainingDuration;
    if (isLockedOut) {
      final getRemainingUseCase = GetLockoutRemainingTimeUseCase(
        storable: storable,
      );
      remainingDuration = await getRemainingUseCase.execute();
    }

    final nowLocked = isLockedOut && remainingDuration != null;

    state = AsyncValue.data(
      ManualLockoutModel(
        isLockedOut: nowLocked,
        remainingDuration: remainingDuration,
        // Timer just expired → completion pending (until share/skip)
        isCompletionPending:
            wasCompletionPending || (wasLockedOut && !nowLocked),
      ),
    );
  }
}

