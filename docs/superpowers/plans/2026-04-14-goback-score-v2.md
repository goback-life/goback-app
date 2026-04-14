# Goback Score v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-signal battery-drain score with a multi-signal composite score using battery drain, charging state, and step count.

**Architecture:** Battery drain remains the base quality signal. Charging state degrades confidence in battery data, shifting weight to step count. Steps are a one-way boost (0 steps = neutral, not a penalty). A new `StepCountService` wraps the `pedometer` package. Charging is tracked via `battery_plus`'s existing `onBatteryStateChanged` stream in the lockout notifier.

**Tech Stack:** Flutter/Dart, `battery_plus` (existing), `pedometer` (new), Supabase migration

**Spec:** `docs/superpowers/specs/2026-04-14-goback-score-v2-design.md`

---

### Task 1: Database migration — add signal columns and update RPC

**Files:**
- Create: `db/migrations/019_lockout_score_signals.sql`
- Create: `supabase/migrations/20260414180000_lockout_score_signals.sql`

- [ ] **Step 1: Write the migration file**

Create `db/migrations/019_lockout_score_signals.sql`:

```sql
-- ============================================================================
-- LOCKOUT SCORE SIGNALS MIGRATION
-- ============================================================================
-- Adds raw signal columns to lockout_sessions for score debugging/tuning.
-- Updates update_lockout_score() RPC to accept and persist new fields.
-- ============================================================================

-- 1. Add columns
ALTER TABLE lockout_sessions
ADD COLUMN IF NOT EXISTS battery_was_charging BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS step_count SMALLINT DEFAULT NULL;

-- 2. Update RPC to accept new signal params
CREATE OR REPLACE FUNCTION update_lockout_score(
  p_session_id UUID,
  p_score INT,
  p_battery_was_charging BOOLEAN DEFAULT NULL,
  p_step_count INT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Verify user is owner or participant
  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  UPDATE lockout_sessions
  SET goback_score = LEAST(100, GREATEST(0, p_score)),
      battery_was_charging = p_battery_was_charging,
      step_count = CASE WHEN p_step_count IS NOT NULL
                        THEN LEAST(32767, GREATEST(0, p_step_count))
                        ELSE NULL END
  WHERE id = p_session_id;

  RETURN json_build_object('success', true);
END;
$$;
```

- [ ] **Step 2: Copy to supabase migrations directory**

Copy the same content to `supabase/migrations/20260414180000_lockout_score_signals.sql`.

- [ ] **Step 3: Commit**

```bash
git add db/migrations/019_lockout_score_signals.sql supabase/migrations/20260414180000_lockout_score_signals.sql
git commit -m "feat: add battery_was_charging and step_count columns to lockout_sessions"
```

---

### Task 2: Write failing tests for GobackScoreCalculator v2

**Files:**
- Create: `test/core/features/lockout/domain/utilities/goback_score_calculator_test.dart`

- [ ] **Step 1: Write tests covering all cases from the design spec**

Create `test/core/features/lockout/domain/utilities/goback_score_calculator_test.dart`:

```dart
import 'package:cloudless/core/features/lockout/domain/utilities/goback_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GobackScoreCalculator', () {
    // ── Duration gate ──────────────────────────────────────────────────
    test('returns null when duration <= 60 seconds', () {
      expect(
        GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 75,
          duration: const Duration(seconds: 60),
        ),
        isNull,
      );
    });

    // ── Case 1: battery available, no charging ─────────────────────────
    group('Case 1 — battery available, no charging', () {
      test('low drain + no steps gives high score', () {
        // 80→78 over 2 hours = 1%/hr (below 2%/hr idle threshold)
        // batteryQuality = 1.0, stepBonus = 0.0, quality = 1.0
        // timeMultiplier = 0.7 + 0.3 * (120/240) = 0.85
        // score = 1.0 * 100 * 0.85 = 85
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 78,
          duration: const Duration(hours: 2),
        );
        expect(score, 85);
      });

      test('low drain + steps boosts score', () {
        // 80→78 over 2 hours = 1%/hr → batteryQuality = 1.0
        // 4000 steps / 2 hours = 2000 steps/hr
        // stepBonus = 0.3 * (2000/3000) = 0.2
        // quality = (1.0 + 0.2).clamp = 1.0
        // timeMultiplier = 0.85
        // score = 1.0 * 100 * 0.85 = 85 (capped at quality 1.0)
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 78,
          duration: const Duration(hours: 2),
          steps: 4000,
        );
        expect(score, 85);
      });

      test('moderate drain + steps rescues score', () {
        // 80→64 over 2 hours = 8%/hr
        // batteryQuality = (1.0 - (8-2)/13) = 0.538
        // 6000 steps / 2 hours = 3000 steps/hr
        // stepBonus = 0.3 * 1.0 = 0.3
        // quality = (0.538 + 0.3).clamp = 0.838
        // timeMultiplier = 0.85
        // score = 0.838 * 100 * 0.85 = 71
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 64,
          duration: const Duration(hours: 2),
          steps: 6000,
        );
        expect(score, 71);
      });

      test('heavy drain gives low score', () {
        // 80→50 over 2 hours = 15%/hr
        // batteryQuality = (1.0 - (15-2)/13) = 0.0
        // stepBonus = 0.0
        // quality = 0.0
        // score = 0
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 50,
          duration: const Duration(hours: 2),
        );
        expect(score, 0);
      });
    });

    // ── Case 2: battery available, WAS charging ────────────────────────
    group('Case 2 — battery available, was charging', () {
      test('charging + steps gives good score', () {
        // wasCharging = true, steps present
        // stepBonus = 0.3 * (3000/2 / 3000) = 0.3 * 0.5 = 0.15
        // quality = (0.7 + 0.15) = 0.85
        // timeMultiplier = 0.85
        // score = 0.85 * 100 * 0.85 = 72
        final score = GobackScoreCalculator.calculate(
          batteryStart: 50,
          batteryEnd: 90,
          duration: const Duration(hours: 2),
          steps: 3000,
          wasCharging: true,
        );
        expect(score, 72);
      });

      test('charging + no steps + low drain caps at 70 range', () {
        // wasCharging = true, no steps
        // batteryDrain: 50→90 → max(0, 50-90) = 0 → drainPerHour = 0
        // batteryQuality = (1.0 - (0-2)/13) = (1.0 + 0.154) clamped = 1.0
        // but capped at 0.7
        // quality = 0.7
        // timeMultiplier = 0.85
        // score = 0.7 * 100 * 0.85 = 60 (was capped, so limited)
        final score = GobackScoreCalculator.calculate(
          batteryStart: 50,
          batteryEnd: 90,
          duration: const Duration(hours: 2),
          wasCharging: true,
        );
        expect(score, inInclusiveRange(55, 65));
      });

      test('charging + no steps + high drain gives low score', () {
        // wasCharging = true, no steps
        // batteryDrain: 80→60 → drain = 20, drainPerHour = 10
        // batteryQuality = (1.0 - (10-2)/13) = 0.385
        // capped at 0.7, so quality = 0.385 (below cap)
        // timeMultiplier = 0.85
        // score = 0.385 * 100 * 0.85 = 33
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 60,
          duration: const Duration(hours: 2),
          wasCharging: true,
        );
        expect(score, inInclusiveRange(30, 35));
      });
    });

    // ── Case 3: no battery data ────────────────────────────────────────
    group('Case 3 — no battery data', () {
      test('no battery + no steps gives time-only score', () {
        // quality = 0.7
        // timeMultiplier = 0.85
        // score = 0.7 * 100 * 0.85 = 60
        final score = GobackScoreCalculator.calculate(
          batteryStart: null,
          batteryEnd: null,
          duration: const Duration(hours: 2),
        );
        expect(score, 60);
      });

      test('no battery + steps boosts above fallback', () {
        // stepBonus = 0.3 * (6000/2 / 3000) = 0.3 * 1.0 = 0.3
        // quality = (0.7 + 0.3) = 1.0
        // timeMultiplier = 0.85
        // score = 1.0 * 100 * 0.85 = 85
        final score = GobackScoreCalculator.calculate(
          batteryStart: null,
          batteryEnd: null,
          duration: const Duration(hours: 2),
          steps: 6000,
        );
        expect(score, 85);
      });
    });

    // ── Time multiplier ────────────────────────────────────────────────
    group('time multiplier', () {
      test('short lockout gets 0.7x multiplier', () {
        // 5 minutes, low drain
        // batteryQuality = 1.0 (2%/hr)
        // timeMultiplier = 0.7 + 0.3 * (5/240) ≈ 0.706
        // score ≈ 71
        final score = GobackScoreCalculator.calculate(
          batteryStart: 100,
          batteryEnd: 100,
          duration: const Duration(minutes: 5),
        );
        expect(score, inInclusiveRange(70, 72));
      });

      test('4+ hour lockout gets 1.0x multiplier', () {
        // 5 hours, low drain
        // timeMultiplier = 1.0 (capped)
        // batteryQuality = 1.0
        // score = 100
        final score = GobackScoreCalculator.calculate(
          batteryStart: 80,
          batteryEnd: 78,
          duration: const Duration(hours: 5),
        );
        expect(score, 100);
      });
    });

    // ── Step bonus cap ─────────────────────────────────────────────────
    test('step bonus caps at 0.3 regardless of step count', () {
      // 20000 steps in 1 hour = 20000 steps/hr (way over 3000 cap)
      // stepBonus = 0.3 * (20000/3000).clamp(0,1) = 0.3 * 1.0 = 0.3
      // No battery → quality = (0.7 + 0.3) = 1.0
      // timeMultiplier at 1hr = 0.7 + 0.3 * (60/240) = 0.775
      // score = 1.0 * 100 * 0.775 = 78
      final score = GobackScoreCalculator.calculate(
        batteryStart: null,
        batteryEnd: null,
        duration: const Duration(hours: 1),
        steps: 20000,
      );
      expect(score, 78);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/core/features/lockout/domain/utilities/goback_score_calculator_test.dart`

Expected: Multiple failures — the current calculator doesn't accept `steps` or `wasCharging` parameters.

- [ ] **Step 3: Commit failing tests**

```bash
git add test/core/features/lockout/domain/utilities/goback_score_calculator_test.dart
git commit -m "test: add failing tests for goback score v2 multi-signal formula"
```

---

### Task 3: Implement GobackScoreCalculator v2

**Files:**
- Modify: `lib/core/features/lockout/domain/utilities/goback_score_calculator.dart`

- [ ] **Step 1: Replace the calculator with the new formula**

Replace the entire contents of `goback_score_calculator.dart`:

```dart
import 'dart:math';

/// Calculates the goback score (0-100) based on battery drain, charging state,
/// and step count.
///
/// Battery drain is the primary signal when reliable (no charging detected).
/// Steps provide a one-way boost — high steps = corroboration of disconnection,
/// but 0 steps is neutral (meditation, reading, napping are valid).
/// Charging degrades battery signal confidence, shifting weight to steps.
class GobackScoreCalculator {
  const GobackScoreCalculator._();

  /// Returns null only if duration is too short (<= 60s).
  ///
  /// When battery data is unavailable, falls back to a time-only score
  /// (0.7 base) boosted by steps if available.
  static int? calculate({
    required int? batteryStart,
    required int? batteryEnd,
    required Duration duration,
    int? steps,
    bool wasCharging = false,
  }) {
    if (duration.inSeconds <= 60) return null;

    final durationMinutes = duration.inMinutes.toDouble();
    final durationHours = duration.inSeconds / 3600.0;

    // Time multiplier: 0.7 at 0 min → 1.0 at 4 hrs
    final timeMultiplier =
        0.7 + 0.3 * (durationMinutes / 240.0).clamp(0.0, 1.0);

    // Step bonus: 0.0 (no data / 0 steps) → 0.3 (≥3000 steps/hr)
    final stepBonus = steps != null && steps > 0
        ? 0.3 * ((steps / durationHours) / 3000.0).clamp(0.0, 1.0)
        : 0.0;

    final hasBattery = batteryStart != null && batteryEnd != null;

    double quality;

    if (hasBattery && !wasCharging) {
      // Case 1: battery reliable, steps are a bonus
      final drain = max(0, batteryStart! - batteryEnd!);
      final drainPerHour = drain / durationHours;
      final batteryQuality =
          (1.0 - (drainPerHour - 2.0) / 13.0).clamp(0.0, 1.0);
      quality = (batteryQuality + stepBonus).clamp(0.0, 1.0);
    } else if (hasBattery && wasCharging) {
      // Case 2: battery unreliable due to charging
      if (stepBonus > 0) {
        // Steps rescue the score
        quality = (0.7 + stepBonus).clamp(0.0, 1.0);
      } else {
        // No steps — use battery but cap at 0.7
        final drain = max(0, batteryStart! - batteryEnd!);
        final drainPerHour = drain / durationHours;
        final batteryQuality =
            (1.0 - (drainPerHour - 2.0) / 13.0).clamp(0.0, 1.0);
        quality = batteryQuality.clamp(0.0, 0.7);
      }
    } else {
      // Case 3: no battery data — fallback + step bonus
      quality = (0.7 + stepBonus).clamp(0.0, 1.0);
    }

    return (quality * 100.0 * timeMultiplier).round().clamp(0, 100);
  }
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `fvm flutter test test/core/features/lockout/domain/utilities/goback_score_calculator_test.dart`

Expected: All tests PASS.

- [ ] **Step 3: Run full analyzer**

Run: `fvm flutter analyze lib/core/features/lockout/domain/utilities/goback_score_calculator.dart`

Expected: No new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/lockout/domain/utilities/goback_score_calculator.dart
git commit -m "feat: implement goback score v2 with multi-signal composite formula"
```

---

### Task 4: Add pedometer dependency and platform permissions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add pedometer to pubspec.yaml**

Add `pedometer: ^4.0.2` to the dependencies section in `pubspec.yaml`, near the existing `battery_plus` entry.

- [ ] **Step 2: Run pub get**

Run: `fvm flutter pub get`

Expected: Resolves successfully.

- [ ] **Step 3: Add NSMotionUsageDescription to Info.plist**

In `ios/Runner/Info.plist`, add after the existing `NSPhotoLibraryUsageDescription` entry:

```xml
<key>NSMotionUsageDescription</key>
<string>GoBack uses step count to measure how active you were during your lockout</string>
```

- [ ] **Step 4: Add ACTIVITY_RECOGNITION permission to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, add with the other `uses-permission` entries:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "feat: add pedometer dependency and motion permissions"
```

---

### Task 5: Create StepCountService

**Files:**
- Create: `lib/core/features/lockout/data/services/step_count_service.dart`
- Create: `lib/core/features/lockout/data/providers/step_count_service_provider.dart`

- [ ] **Step 1: Create StepCountService**

Create `lib/core/features/lockout/data/services/step_count_service.dart`:

```dart
import 'dart:async';

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:pedometer/pedometer.dart';

/// Tracks step count during a lockout session.
///
/// Subscribes to the device pedometer at lockout start and accumulates steps.
/// On iOS, CMPedometer buffers steps while the app is suspended and delivers
/// them when the app resumes — no background task needed.
///
/// If motion permission is denied, [getStepsSinceStart] returns null and
/// the score calculator treats this as neutral (no penalty).
class StepCountService {
  StreamSubscription<StepCount>? _subscription;
  int? _baselineSteps;
  int? _latestSteps;

  /// Begins tracking steps. Call at lockout start.
  void startTracking() {
    _baselineSteps = null;
    _latestSteps = null;
    _subscription?.cancel();

    _subscription = Pedometer.stepCountStream.listen(
      (event) {
        _baselineSteps ??= event.steps;
        _latestSteps = event.steps;
      },
      onError: (error) {
        // Permission denied or sensor unavailable — silent fallback
        logger.warning('Pedometer error (permission denied?)', exception: error);
        _subscription?.cancel();
        _subscription = null;
      },
    );
  }

  /// Returns steps accumulated since [startTracking] was called.
  /// Returns null if tracking was never started, permission was denied,
  /// or no step events were received.
  int? getStepsSinceStart() {
    if (_baselineSteps == null || _latestSteps == null) return null;
    return _latestSteps! - _baselineSteps!;
  }

  /// Stops tracking and cleans up the subscription.
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _baselineSteps = null;
    _latestSteps = null;
  }
}
```

- [ ] **Step 2: Create the provider**

Create `lib/core/features/lockout/data/providers/step_count_service_provider.dart`:

```dart
import 'package:cloudless/core/features/lockout/data/services/step_count_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'step_count_service_provider.g.dart';

@Riverpod(keepAlive: true)
StepCountService stepCountService(StepCountServiceRef ref) {
  return StepCountService();
}
```

- [ ] **Step 3: Run build_runner to generate the provider**

Run: `fvm dart run build_runner build --delete-conflicting-outputs --build-filter="lib/core/features/lockout/data/providers/step_count_service_provider.dart"`

Expected: Generates `step_count_service_provider.g.dart`.

- [ ] **Step 4: Verify no analyzer errors**

Run: `fvm flutter analyze lib/core/features/lockout/data/services/step_count_service.dart lib/core/features/lockout/data/providers/step_count_service_provider.dart`

Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/core/features/lockout/data/services/step_count_service.dart lib/core/features/lockout/data/providers/step_count_service_provider.dart lib/core/features/lockout/data/providers/step_count_service_provider.g.dart
git commit -m "feat: add StepCountService for pedometer tracking during lockouts"
```

---

### Task 6: Update ManualLockoutStorable — add wasChargingDuringLockout

**Files:**
- Modify: `lib/core/features/lockout/data/storables/manual_lockout_storable.dart`

- [ ] **Step 1: Add wasChargingDuringLockout to storage map and accessors**

In `manual_lockout_storable.dart`, add `'wasChargingDuringLockout': false` to the default map in `getLockoutData()`:

```dart
Future<Map<String, dynamic>> getLockoutData() async {
    final data = await get(
      defaultValue: <String, dynamic>{
        'lockoutEndTimestamp': null,
        'lockoutStartTimestamp': null,
        'lockoutSessionId': null,
        'batteryAtStart': null,
        'isOpenEnded': false,
        'venueName': null,
        'venueTagId': null,
        'wasChargingDuringLockout': false,
      },
    );
```

Add `wasChargingDuringLockout` parameter to `setLockoutData()`:

```dart
Future<void> setLockoutData({
    required DateTime lockoutEndTimestamp,
    required DateTime lockoutStartTimestamp,
    String? lockoutSessionId,
    int? batteryAtStart,
    bool isOpenEnded = false,
    String? venueName,
    String? venueTagId,
    bool wasChargingDuringLockout = false,
  }) async {
    final dataToStore = <String, dynamic>{
      'lockoutEndTimestamp': lockoutEndTimestamp.toIso8601String(),
      'lockoutStartTimestamp': lockoutStartTimestamp.toIso8601String(),
      'lockoutSessionId': lockoutSessionId,
      'batteryAtStart': batteryAtStart,
      'isOpenEnded': isOpenEnded,
      'venueName': venueName,
      'venueTagId': venueTagId,
      'wasChargingDuringLockout': wasChargingDuringLockout,
    };
```

Add a getter method:

```dart
Future<bool> getWasChargingDuringLockout() async {
    final data = await getLockoutData();
    return (data['wasChargingDuringLockout'] as bool?) ?? false;
  }
```

Add a setter for updating the flag mid-lockout:

```dart
Future<void> setWasChargingDuringLockout(bool value) async {
    final data = await getLockoutData();
    data['wasChargingDuringLockout'] = value;
    await set(data);
  }
```

Update `clearLockout()` to include the new field:

```dart
Future<void> clearLockout() async {
    await set(<String, dynamic>{
      'lockoutEndTimestamp': null,
      'lockoutStartTimestamp': null,
      'lockoutSessionId': null,
      'batteryAtStart': null,
      'isOpenEnded': false,
      'venueName': null,
      'venueTagId': null,
      'wasChargingDuringLockout': false,
    });
  }
```

- [ ] **Step 2: Verify no analyzer errors**

Run: `fvm flutter analyze lib/core/features/lockout/data/storables/manual_lockout_storable.dart`

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/features/lockout/data/storables/manual_lockout_storable.dart
git commit -m "feat: add wasChargingDuringLockout to ManualLockoutStorable"
```

---

### Task 7: Update ManualLockoutNotifier — track charging and steps during lockout

**Files:**
- Modify: `lib/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart`

- [ ] **Step 1: Add imports and charging/step tracking to lockout start methods**

Add imports at the top of the file:

```dart
import 'dart:async';
import 'package:cloudless/core/features/lockout/data/providers/step_count_service_provider.dart';
```

Add a `StreamSubscription` field and a charging tracking helper inside the `ManualLockoutNotifier` class, after the `_captureBattery` method:

```dart
StreamSubscription<BatteryState>? _chargingSubscription;

/// Starts monitoring charging state and step count for the active lockout.
void _startLockoutTracking() {
    // Track charging events
    _chargingSubscription?.cancel();
    _chargingSubscription = Battery().onBatteryStateChanged.listen(
      (batteryState) {
        if (batteryState == BatteryState.charging ||
            batteryState == BatteryState.full) {
          ref
              .read(manualLockoutStorableProvider)
              .setWasChargingDuringLockout(true);
        }
      },
    );

    // Start step tracking
    ref.read(stepCountServiceProvider).startTracking();
  }

  /// Stops charging and step monitoring.
  void _stopLockoutTracking() {
    _chargingSubscription?.cancel();
    _chargingSubscription = null;
    ref.read(stepCountServiceProvider).stopTracking();
  }
```

- [ ] **Step 2: Call tracking methods in setLockout**

In the `setLockout` method, add `_startLockoutTracking()` after the `SetManualLockoutUseCase` call (after line 129):

```dart
      await SetManualLockoutUseCase(
        storable: storable,
        duration: duration,
        sessionId: sessionId,
        batteryAtStart: batteryAtStart,
      ).execute();

      _startLockoutTracking();
```

- [ ] **Step 3: Call tracking methods in startVenueLockout**

In the `startVenueLockout` method, add `_startLockoutTracking()` after the `storable.setLockoutData` call (after line 198):

```dart
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
```

- [ ] **Step 4: Call tracking methods in joinLockout**

In the `joinLockout` method, add `_startLockoutTracking()` after the `JoinLockoutUseCase` call (after line 333):

```dart
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
```

- [ ] **Step 5: Stop tracking in clearLockout**

In the `clearLockout` method, add `_stopLockoutTracking()` at the beginning of the try block:

```dart
    try {
      _stopLockoutTracking();
      await ref.read(lockoutLiveActivityServiceProvider).endActivity();
```

- [ ] **Step 6: Verify no analyzer errors**

Run: `fvm flutter analyze lib/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart`

Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart
git commit -m "feat: track charging state and step count during lockout sessions"
```

---

### Task 8: Update LockoutSessionService — persist raw signals

**Files:**
- Modify: `lib/core/features/lockout/data/services/lockout_session_service.dart`

- [ ] **Step 1: Update updateScore method signature and RPC call**

In `lockout_session_service.dart`, update the `updateScore` method to accept and pass the new parameters:

```dart
  /// Updates the goback score and raw signal data for a lockout session.
  FutureResult<void> updateScore({
    required String sessionId,
    required int score,
    bool? batteryWasCharging,
    int? stepCount,
  }) async {
    try {
      await supabase.rpc(
        'update_lockout_score',
        params: {
          'p_session_id': sessionId,
          'p_score': score,
          'p_battery_was_charging': batteryWasCharging,
          'p_step_count': stepCount,
        },
      );
      return Result.success(null);
    } catch (e) {
      logger.warning('Failed to update lockout score: $e');
      return Result.failure(
        e is Exception ? e : Exception('Failed to update score: $e'),
      );
    }
  }
```

- [ ] **Step 2: Verify no analyzer errors**

Run: `fvm flutter analyze lib/core/features/lockout/data/services/lockout_session_service.dart`

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/features/lockout/data/services/lockout_session_service.dart
git commit -m "feat: pass raw score signals (charging, steps) to update_lockout_score RPC"
```

---

### Task 9: Wire it all together in ManualLockoutView

**Files:**
- Modify: `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`

- [ ] **Step 1: Add step count service import**

Add at the top of `manual_lockout_view.dart`:

```dart
import 'package:cloudless/core/features/lockout/data/providers/step_count_service_provider.dart';
```

- [ ] **Step 2: Update onLockoutComplete to pass new signals**

In the `onLockoutComplete` function inside `build()`, update the score calculation and upload section (around lines 109-143). Replace the block from `final storable =` through `await sessionService.updateScore(...)`:

```dart
      // Compute score from battery + charging + steps
      final storable = ref.read(manualLockoutStorableProvider);
      final batteryStart = await storable.getBatteryAtStart();
      final wasCharging = await storable.getWasChargingDuringLockout();
      final lockoutStart = await storable.getLockoutStart();

      // Read step count from the tracking service
      final stepService = ref.read(stepCountServiceProvider);
      final steps = stepService.getStepsSinceStart();
      stepService.stopTracking();

      if (lockoutStart != null) {
        final duration = DateTime.now().difference(lockoutStart);
        lockoutDurationMinutes.value = duration.inMinutes;

        // For open-ended: show elapsed time at end
        if (isOpenEnded.value) {
          countdown.value = _formatElapsed(duration);
        } else {
          countdown.value = '0:00';
        }

        int? batteryEnd;
        try {
          batteryEnd = await Battery().batteryLevel;
        } catch (e) {
          logger.warning('Battery read failed', exception: e);
        }

        final score = GobackScoreCalculator.calculate(
          batteryStart: batteryStart,
          batteryEnd: batteryEnd,
          duration: duration,
          steps: steps,
          wasCharging: wasCharging,
        );
        gobackScore.value = score;

        // Upload score and raw signals to server
        final sid = sessionId.value;
        if (score != null && sid.isNotEmpty) {
          final sessionService = ref.read(lockoutSessionServiceProvider);
          await sessionService.updateScore(
            sessionId: sid,
            score: score,
            batteryWasCharging: wasCharging,
            stepCount: steps,
          );
        }
      }
```

- [ ] **Step 3: Verify no analyzer errors**

Run: `fvm flutter analyze lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`

Expected: No issues.

- [ ] **Step 4: Run all tests**

Run: `fvm flutter test`

Expected: All tests pass, including the goback score v2 tests from Task 2.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart
git commit -m "feat: wire multi-signal score calculation into lockout completion flow"
```

---

### Task 10: Update stage migrations tracker

**Files:**
- Modify: `memory/project_stage_migrations.md` (if migration is pushed to stage)

- [ ] **Step 1: After pushing migration to stage, update the tracker**

Add `019_lockout_score_signals` to the pending stage migrations list in `memory/project_stage_migrations.md`.

- [ ] **Step 2: Commit**

```bash
git add memory/project_stage_migrations.md
git commit -m "docs: track lockout score signals migration in stage migrations list"
```
