import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_live_activity_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/step_count_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:cloudless/core/features/lockout/domain/models/manual_lockout_model.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/check_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/clear_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/get_lockout_remaining_time_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/join_lockout_use_case.dart';
import 'package:cloudless/core/features/lockout/domain/use_cases/set_manual_lockout_use_case.dart';
import 'package:cloudless/core/features/nfc/domain/models/venue_tag_model.dart';
import 'package:cloudless/core/features/notification/domain/providers/scheduled_notification_provider.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_lockout_notifier_provider.g.dart';

/// Sentinel duration for open-ended venue lockouts.
/// Keeps [isLockedOut] true indefinitely until the user ends the session.
const _kOpenEndedSentinel = Duration(days: 30);

@Riverpod(keepAlive: true)
class ManualLockoutNotifier extends _$ManualLockoutNotifier {
  @override
  Future<ManualLockoutModel> build() async {
    final storable = ref.watch(manualLockoutStorableProvider);
    final currentState = await _readLockoutState(storable);

    // Sync Live Activity with lockout state on app launch / rebuild
    final liveActivityService = ref.read(lockoutLiveActivityServiceProvider);
    if (currentState.isLockedOut) {
      final isOpenEnded = await storable.getIsOpenEnded();
      final lockoutEnd = await storable.getLockoutEnd();
      final lockoutStart = await storable.getLockoutStart();
      if (lockoutEnd != null) {
        await liveActivityService.startActivity(
          lockoutEndTimestamp: lockoutEnd,
          lockoutStartTimestamp: lockoutStart,
          isOpenEnded: isOpenEnded,
        );
      }
    } else {
      await liveActivityService.endActivity();
    }

    return currentState;
  }

  /// Reads lockout state (including open-ended and venue fields) from storable.
  Future<ManualLockoutModel> _readLockoutState(
    ManualLockoutStorable storable,
  ) async {
    final isLockedOut = await CheckManualLockoutUseCase(
      storable: storable,
    ).execute();

    Duration? remainingDuration;
    if (isLockedOut) {
      remainingDuration = await GetLockoutRemainingTimeUseCase(
        storable: storable,
      ).execute();
    }

    final isOpenEnded = await storable.getIsOpenEnded();
    final venueName = await storable.getVenueName();
    final lockoutStartTime = await storable.getLockoutStart();

    return ManualLockoutModel(
      isLockedOut: isLockedOut && remainingDuration != null,
      remainingDuration: remainingDuration,
      isOpenEnded: isOpenEnded,
      venueName: venueName,
      lockoutStartTime: lockoutStartTime,
    );
  }

  /// Captures battery level, returning null on failure.
  Future<int?> _captureBattery() async {
    try {
      return await Battery().batteryLevel;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<BatteryState>? _chargingSubscription;

  /// Starts monitoring charging state and step count for the active lockout.
  void _startLockoutTracking() {
    // Track charging events
    _chargingSubscription?.cancel();
    _chargingSubscription = Battery().onBatteryStateChanged.listen((
      batteryState,
    ) {
      if (batteryState == BatteryState.charging ||
          batteryState == BatteryState.full) {
        ref
            .read(manualLockoutStorableProvider)
            .setWasChargingDuringLockout(value: true);
      }
    });

    // Start step tracking
    ref.read(stepCountServiceProvider).startTracking();
  }

  /// Stops charging and step monitoring.
  void _stopLockoutTracking() {
    _chargingSubscription?.cancel();
    _chargingSubscription = null;
    ref.read(stepCountServiceProvider).stopTracking();
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

    final batteryAtStart = await _captureBattery();

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
          debugPrint('[LockoutNotifier] Session created: $sessionId');
        },
        (error) {
          debugPrint('[LockoutNotifier] FAILED to create session: $error');
        },
      );

      // Store locally with session ID for post creation after lockout ends
      logger.info('Storing lockout locally with sessionId: $sessionId');
      await SetManualLockoutUseCase(
        storable: storable,
        duration: duration,
        sessionId: sessionId,
        batteryAtStart: batteryAtStart,
      ).execute();
      _startLockoutTracking();

      // Start Live Activity countdown on lock screen
      final lockoutEndTime = DateTime.now().add(duration);
      await ref
          .read(lockoutLiveActivityServiceProvider)
          .startActivity(lockoutEndTimestamp: lockoutEndTime);

      // Schedule mid-lockout + post-lockout notifications, cancel daily
      await ref
          .read(scheduledNotificationProvider)
          .scheduleLockoutNotifications(lockoutEndTime);

      state = AsyncValue.data(await _readLockoutState(storable));

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

  /// Starts an open-ended venue lockout triggered by scanning an NFC tag.
  ///
  /// Uses a 30-day sentinel end time so the lockout stays active until
  /// the user explicitly ends it by tapping the tag again.
  Future<String?> startVenueLockout(VenueTagModel venue) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final sessionService = ref.read(lockoutSessionServiceProvider);
    state = const AsyncValue.loading();
    String? sessionId;

    final batteryAtStart = await _captureBattery();

    try {
      // Ensure venue exists in DB before creating the session (FK constraint)
      await sessionService.upsertVenue(
        venueId: venue.venueId,
        venueName: venue.venueName,
      );

      final sessionResult = await sessionService.createSession(
        duration: _kOpenEndedSentinel,
        locationName: venue.venueName,
        venueTagId: venue.venueId,
        isOpenEnded: true,
      );

      sessionResult.fold(
        (session) {
          sessionId = session.id;
          logger.info(
            'Venue lockout session created: $sessionId (${venue.venueName})',
          );
        },
        (error) => logger.warning('Failed to create venue DB session: $error'),
      );

      final now = DateTime.now();
      final sentinelEnd = now.add(_kOpenEndedSentinel);

      await storable.setLockoutData(
        lockoutEndTimestamp: sentinelEnd,
        lockoutStartTimestamp: now,
        lockoutSessionId: sessionId,
        batteryAtStart: batteryAtStart,
        isOpenEnded: true,
        venueName: venue.venueName,
        venueTagId: venue.venueId,
      );
      _startLockoutTracking();

      // Start Live Activity in count-up mode for open-ended lockouts
      await ref
          .read(lockoutLiveActivityServiceProvider)
          .startActivity(
            lockoutEndTimestamp: sentinelEnd,
            lockoutStartTimestamp: now,
            isOpenEnded: true,
          );

      // Schedule a 1-hour encouragement notification using venue name
      await ref
          .read(scheduledNotificationProvider)
          .scheduleLockoutNotifications(
            sentinelEnd,
            venueName: venue.venueName,
          );

      state = AsyncValue.data(await _readLockoutState(storable));

      logger.info('Venue lockout started at ${venue.venueName}');
      return sessionId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error(
        'Error starting venue lockout',
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
      const ManualLockoutModel(isLockedOut: false, isCompletionPending: false),
    );
  }

  Future<void> clearLockout() async {
    final storable = ref.read(manualLockoutStorableProvider);
    final useCase = ClearManualLockoutUseCase(storable: storable);

    state = const AsyncValue.loading();
    try {
      _stopLockoutTracking();
      await ref.read(lockoutLiveActivityServiceProvider).endActivity();
      await ref
          .read(scheduledNotificationProvider)
          .cancelLockoutNotifications();
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
    return await GetLockoutRemainingTimeUseCase(storable: storable).execute();
  }

  /// Joins an existing lockout session by session ID.
  ///
  /// Calls the database RPC to join and stores locally.
  /// For venue (open-ended) lockouts, stores venue metadata locally so the
  /// lockout UI shows the correct venue name and count-up timer.
  Future<void> joinLockout(String lockoutSessionId) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final sessionService = ref.read(lockoutSessionServiceProvider);

    final batteryAtStart = await _captureBattery();

    state = const AsyncValue.loading();
    try {
      // Get session details to determine end time and venue info
      final sessionResult = await sessionService.getSessionById(
        lockoutSessionId,
      );
      DateTime? lockoutEndTime;
      bool isOpenEnded = false;
      String? venueName;
      String? venueTagId;
      Exception? sessionError;

      await sessionResult.asyncFold(
        (session) async {
          if (session != null) {
            lockoutEndTime = DateTime.parse(session.endsAt);
            isOpenEnded = session.isOpenEnded;
            venueName = session.locationName;
            venueTagId = session.venueTagId;

            // Join session in database - check result for RPC errors
            final joinResult = await sessionService.joinSession(
              sessionId: lockoutSessionId,
            );
            joinResult.fold((_) {}, (error) {
              sessionError = error;
            });
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
      await JoinLockoutUseCase(
        storable: storable,
        lockoutEndTime: lockoutEndTime!,
        lockoutSessionId: lockoutSessionId,
        batteryAtStart: batteryAtStart,
        isOpenEnded: isOpenEnded,
        venueName: venueName,
        venueTagId: venueTagId,
      ).execute();
      _startLockoutTracking();

      if (isOpenEnded) {
        // Start Live Activity in count-up mode for open-ended lockouts
        await ref
            .read(lockoutLiveActivityServiceProvider)
            .startActivity(
              lockoutEndTimestamp: lockoutEndTime!,
              lockoutStartTimestamp: DateTime.now(),
              isOpenEnded: true,
            );

        // Schedule a 1-hour encouragement notification using venue name
        await ref
            .read(scheduledNotificationProvider)
            .scheduleLockoutNotifications(
              lockoutEndTime!,
              venueName: venueName,
            );
      } else {
        // Start Live Activity countdown on lock screen
        await ref
            .read(lockoutLiveActivityServiceProvider)
            .startActivity(lockoutEndTimestamp: lockoutEndTime!);

        // Schedule mid-lockout + post-lockout notifications, cancel daily
        await ref
            .read(scheduledNotificationProvider)
            .scheduleLockoutNotifications(lockoutEndTime!);
      }

      state = AsyncValue.data(await _readLockoutState(storable));

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

    final wasLockedOut = state.value?.isLockedOut ?? false;
    final wasCompletionPending = state.value?.isCompletionPending ?? false;
    final wasOpenEnded = state.value?.isOpenEnded ?? false;

    final currentState = await _readLockoutState(storable);

    state = AsyncValue.data(
      ManualLockoutModel(
        isLockedOut: currentState.isLockedOut,
        remainingDuration: currentState.remainingDuration,
        isOpenEnded: currentState.isOpenEnded,
        venueName: currentState.venueName,
        lockoutStartTime: currentState.lockoutStartTime,
        // Open-ended lockouts never expire automatically — completion is
        // triggered only by an explicit NFC tap-out.
        isCompletionPending:
            wasCompletionPending ||
            (!wasOpenEnded && wasLockedOut && !currentState.isLockedOut),
      ),
    );
  }
}
