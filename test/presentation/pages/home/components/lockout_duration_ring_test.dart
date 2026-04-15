import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_ring_painter.dart';

void main() {
  group('durationToSweepAngle', () {
    test('30 minutes = π/10', () {
      final angle = durationToSweepAngle(const Duration(minutes: 30));
      expect(angle, closeTo(pi / 10, 0.001));
    });

    test('1 hour = π/5', () {
      final angle = durationToSweepAngle(const Duration(hours: 1));
      expect(angle, closeTo(pi / 5, 0.001));
    });

    test('5 hours = π (half circle)', () {
      final angle = durationToSweepAngle(const Duration(hours: 5));
      expect(angle, closeTo(pi, 0.001));
    });

    test('10 hours = 2π (full circle)', () {
      final angle = durationToSweepAngle(const Duration(hours: 10));
      expect(angle, closeTo(2 * pi, 0.001));
    });

    test('0 minutes = 0', () {
      final angle = durationToSweepAngle(Duration.zero);
      expect(angle, closeTo(0, 0.001));
    });
  });

  group('angleToDuration', () {
    test('π/10 = 30 minutes', () {
      final duration = angleToDuration(pi / 10);
      expect(duration.inMinutes, 30);
    });

    test('π/5 = 60 minutes', () {
      final duration = angleToDuration(pi / 5);
      expect(duration.inMinutes, 60);
    });

    test('π = 5 hours', () {
      final duration = angleToDuration(pi);
      expect(duration.inMinutes, 300);
    });

    test('2π = 10 hours', () {
      final duration = angleToDuration(2 * pi);
      expect(duration.inMinutes, 600);
    });
  });

  group('snapDuration', () {
    test('snaps 37 minutes to 30 with 15-min snap', () {
      final snapped = snapDuration(
        const Duration(minutes: 37),
        snapMinutes: 15,
      );
      expect(snapped.inMinutes, 30);
    });

    test('snaps 38 minutes to 45 with 15-min snap', () {
      final snapped = snapDuration(
        const Duration(minutes: 38),
        snapMinutes: 15,
      );
      expect(snapped.inMinutes, 45);
    });

    test('snaps 7 minutes to 0 but clamps to 30', () {
      final snapped = snapDuration(const Duration(minutes: 7), minMinutes: 30);
      expect(snapped.inMinutes, 30);
    });

    test('exact 15-min boundary stays', () {
      final snapped = snapDuration(
        const Duration(minutes: 45),
        snapMinutes: 15,
      );
      expect(snapped.inMinutes, 45);
    });

    test('uses 1-min snap when minMinutes < 15', () {
      final snapped = snapDuration(const Duration(minutes: 3), minMinutes: 1);
      expect(snapped.inMinutes, 3);
    });

    test('snaps to max of 10 hours', () {
      final snapped = snapDuration(const Duration(hours: 11));
      expect(snapped.inMinutes, 600);
    });
  });

  group('polarAngleFromPoint', () {
    test('12 o clock returns 0', () {
      final angle = polarAngleFromPoint(110, 0, 110, 110);
      expect(angle, closeTo(0, 0.01));
    });

    test('3 o clock returns π/2', () {
      final angle = polarAngleFromPoint(220, 110, 110, 110);
      expect(angle, closeTo(pi / 2, 0.01));
    });

    test('6 o clock returns π', () {
      final angle = polarAngleFromPoint(110, 220, 110, 110);
      expect(angle, closeTo(pi, 0.01));
    });

    test('9 o clock returns 3π/2', () {
      final angle = polarAngleFromPoint(0, 110, 110, 110);
      expect(angle, closeTo(3 * pi / 2, 0.01));
    });
  });
}
