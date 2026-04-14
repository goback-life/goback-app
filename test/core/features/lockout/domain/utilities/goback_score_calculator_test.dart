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
        // score = 0.7 * 100 * 0.85 = 60
        final score = GobackScoreCalculator.calculate(
          batteryStart: 50,
          batteryEnd: 90,
          duration: const Duration(hours: 2),
          wasCharging: true,
        );
        expect(score, 60);
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
        expect(score, 33);
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
