# Lockout Form Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the cluttered lockout dialog with an Apple-inspired glass bottom sheet featuring a sky-filled drag ring for duration selection.

**Architecture:** New bottom sheet replaces `ManualLockoutDialog` while preserving the same return type `({Duration? duration, String? actionText, bool nfcScan})?`. The ring uses a `CustomPainter` with an `ImageShader` from `background_goback.png` clipped to the active arc. All glass effects use the existing `AppGlassContainer`. A DB migration lowers the minimum lockout from 60→30 minutes.

**Tech Stack:** Flutter (FVM) · `HookConsumerWidget` · `CustomPainter` · `GestureDetector` · `AppGlassContainer` · Supabase migration

**Spec:** `docs/superpowers/specs/2026-04-15-lockout-form-redesign.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260415160000_relax_lockout_min_30.sql` | Lower min lockout to 30 min |
| Create | `lib/presentation/pages/home/components/lockout_ring_painter.dart` | CustomPainter: glass track, sky arc, glow, ticks, thumb |
| Create | `lib/presentation/pages/home/components/lockout_duration_ring.dart` | Gesture-driven ring widget, image loading, drag→duration math |
| Create | `lib/presentation/pages/home/components/lockout_activity_chips.dart` | Square chips with line icons, custom chip morph |
| Create | `lib/presentation/pages/home/components/lockout_bottom_sheet.dart` | Glass bottom sheet assembling ring + chips + CTA + NFC |
| Modify | `lib/presentation/pages/home/components/home_lockout_button.dart:26` | Switch from `ManualLockoutDialog.show` → `LockoutBottomSheet.show` |
| Delete | `lib/presentation/pages/home/components/manual_lockout_dialog.dart` | Replaced by bottom sheet |
| Create | `test/presentation/pages/home/components/lockout_duration_ring_test.dart` | Unit tests for angle↔duration math |
| Create | `test/presentation/pages/home/components/lockout_activity_chips_test.dart` | Widget tests for chip selection + custom morph |
| Create | `test/presentation/pages/home/components/lockout_bottom_sheet_test.dart` | Widget tests for sheet return values + validation |

---

### Task 1: DB Migration — Lower minimum lockout to 30 minutes

**Files:**
- Create: `supabase/migrations/20260415160000_relax_lockout_min_30.sql`
- Modify: `lib/presentation/pages/home/components/manual_lockout_dialog.dart:12` (default value)

- [ ] **Step 1: Create migration file**

```sql
-- Relax the timed-lockout minimum from 60 → 30 minutes.
-- The existing trigger `enforce_lockout_min_duration` rejects inserts
-- where ends_at < NOW() + INTERVAL '59 minutes'.
-- Replace it to allow 29 minutes (30-min lockout minus clock skew).

CREATE OR REPLACE FUNCTION public.enforce_lockout_min_duration()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only enforce on timed (non-open-ended) lockouts
  IF NEW.is_open_ended = false AND NEW.ends_at < NOW() + INTERVAL '29 minutes' THEN
    RAISE EXCEPTION 'Timed lockout must be at least 30 minutes';
  END IF;
  RETURN NEW;
END;
$$;
```

- [ ] **Step 2: Update MIN_LOCKOUT_MINUTES default**

In `lib/presentation/pages/home/components/manual_lockout_dialog.dart`, change line 12:

```dart
// Before:
const _kMinLockoutMinutes = int.fromEnvironment(
  'MIN_LOCKOUT_MINUTES',
  defaultValue: 60,
);

// After:
const _kMinLockoutMinutes = int.fromEnvironment(
  'MIN_LOCKOUT_MINUTES',
  defaultValue: 30,
);
```

Note: This constant will be moved into the new bottom sheet file in Task 5. Changing it here first keeps the app functional between tasks.

- [ ] **Step 3: Push migration to stage**

```bash
supabase db push --linked
```

- [ ] **Step 4: Verify migration applied**

```bash
supabase db lint --linked
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260415160000_relax_lockout_min_30.sql \
       lib/presentation/pages/home/components/manual_lockout_dialog.dart
git commit -m "feat: lower minimum lockout duration from 60 to 30 minutes"
```

---

### Task 2: Ring Painter — CustomPainter for the sky-filled clock ring

**Files:**
- Create: `lib/presentation/pages/home/components/lockout_ring_painter.dart`
- Create: `test/presentation/pages/home/components/lockout_duration_ring_test.dart`

This painter draws: glass disc interior, inactive track, sky-filled active arc, soft glow, hour tick marks, and draggable thumb.

- [ ] **Step 1: Write unit tests for angle↔duration conversion helpers**

Create `test/presentation/pages/home/components/lockout_duration_ring_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

// These are the pure functions we'll extract into the painter file.
// We import them after creating the file in Step 3.
// For now, define the expected behavior:

void main() {
  group('durationToSweepAngle', () {
    // Full rotation = 10 hours = 2π
    // 1 hour = 2π / 10 = π/5

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
    test('snaps 37 minutes to 30', () {
      final snapped = snapDuration(const Duration(minutes: 37));
      expect(snapped.inMinutes, 30);
    });

    test('snaps 38 minutes to 45', () {
      final snapped = snapDuration(const Duration(minutes: 38));
      expect(snapped.inMinutes, 45);
    });

    test('snaps 7 minutes to 0 but clamps to 30', () {
      final snapped = snapDuration(const Duration(minutes: 7), minMinutes: 30);
      expect(snapped.inMinutes, 30);
    });

    test('exact 15-min boundary stays', () {
      final snapped = snapDuration(const Duration(minutes: 45));
      expect(snapped.inMinutes, 45);
    });

    test('snaps to max of 10 hours', () {
      final snapped = snapDuration(const Duration(hours: 11));
      expect(snapped.inMinutes, 600);
    });
  });

  group('polarAngleFromPoint', () {
    // center = (110, 110), 12 o'clock = -π/2
    // point at 12 o'clock (110, 0) → angle 0
    // point at 3 o'clock (220, 110) → angle π/2
    // point at 6 o'clock (110, 220) → angle π
    // point at 9 o'clock (0, 110) → angle 3π/2

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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/presentation/pages/home/components/lockout_duration_ring_test.dart
```

Expected: Compilation error — functions not defined.

- [ ] **Step 3: Create the ring painter with math helpers**

Create `lib/presentation/pages/home/components/lockout_ring_painter.dart`:

```dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Maximum lockout duration the ring represents (one full rotation).
const kMaxLockoutDuration = Duration(hours: 10);
const _kMaxMinutes = 600; // 10 * 60
const _kSnapMinutes = 15;
const _kTrackWidth = 14.0;
const kThumbRadius = 15.0;
const _kGlowBlur = 4.0;

// ---------------------------------------------------------------------------
// Pure math helpers (tested in unit tests)
// ---------------------------------------------------------------------------

/// Converts a [Duration] to the sweep angle in radians (0 → 2π).
double durationToSweepAngle(Duration duration) {
  final minutes = duration.inMinutes.clamp(0, _kMaxMinutes);
  return (minutes / _kMaxMinutes) * 2 * pi;
}

/// Converts a sweep angle in radians (0 → 2π) to a [Duration].
Duration angleToDuration(double angle) {
  final clamped = angle.clamp(0.0, 2 * pi);
  final minutes = (clamped / (2 * pi) * _kMaxMinutes).round();
  return Duration(minutes: minutes);
}

/// Snaps a duration to the nearest [_kSnapMinutes] increment, clamped to
/// [minMinutes]..[_kMaxMinutes].
Duration snapDuration(Duration duration, {int minMinutes = 0}) {
  final raw = duration.inMinutes.clamp(0, _kMaxMinutes);
  final snapped = ((raw + _kSnapMinutes ~/ 2) ~/ _kSnapMinutes) * _kSnapMinutes;
  final clamped = snapped.clamp(minMinutes, _kMaxMinutes);
  return Duration(minutes: clamped);
}

/// Returns the clockwise angle in radians from 12-o'clock (0 → 2π)
/// for a point relative to [cx],[cy].
double polarAngleFromPoint(double px, double py, double cx, double cy) {
  // atan2 gives angle from positive-x axis, counter-clockwise.
  // We want clockwise from negative-y axis (12 o'clock).
  final raw = atan2(px - cx, cy - py); // note: swapped args for CW from top
  return raw < 0 ? raw + 2 * pi : raw;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class LockoutRingPainter extends CustomPainter {
  LockoutRingPainter({
    required this.sweepAngle,
    required this.skyImage,
    required this.trackColor,
    required this.glowColor,
    required this.tickColor,
    required this.thumbColor,
  });

  /// Sweep angle of the active arc in radians (0 → 2π).
  final double sweepAngle;

  /// Pre-loaded sky/cloud image for the arc fill.
  final ui.Image? skyImage;

  /// Color for the inactive track ring.
  final Color trackColor;

  /// Color for the glow behind the active arc.
  final Color glowColor;

  /// Color for the hour tick marks.
  final Color tickColor;

  /// Base color for the thumb circle.
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - kThumbRadius;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2; // 12 o'clock

    _drawTrack(canvas, rect);
    _drawTicks(canvas, center, radius);

    if (sweepAngle > 0) {
      _drawGlow(canvas, rect, startAngle);
      _drawSkyArc(canvas, rect, startAngle);
    }

    _drawThumb(canvas, center, radius, startAngle);
  }

  void _drawTrack(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth
      ..color = trackColor;
    canvas.drawCircle(rect.center, rect.width / 2, paint);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = tickColor;

    // Ticks at 12, 3, 6, 9 o'clock
    const tickLength = 8.0;
    for (var i = 0; i < 4; i++) {
      final angle = -pi / 2 + (i * pi / 2);
      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      canvas.drawLine(outerPoint, innerPoint, paint);
    }
  }

  void _drawGlow(Canvas canvas, Rect rect, double startAngle) {
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth + 6
      ..strokeCap = StrokeCap.round
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _kGlowBlur);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  void _drawSkyArc(Canvas canvas, Rect rect, double startAngle) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth
      ..strokeCap = StrokeCap.round;

    if (skyImage != null) {
      // Scale image to fill the bounding rect of the ring
      final scaleX = rect.width / skyImage!.width;
      final scaleY = rect.height / skyImage!.height;
      final scale = max(scaleX, scaleY);
      final matrix = Matrix4.identity()
        ..translate(rect.left, rect.top)
        ..scale(scale, scale);

      arcPaint.shader = ImageShader(
        skyImage!,
        TileMode.clamp,
        TileMode.clamp,
        matrix.storage,
      );
    } else {
      // Fallback: solid accent color
      arcPaint.color = thumbColor;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  void _drawThumb(Canvas canvas, Offset center, double radius, double startAngle) {
    final thumbAngle = startAngle + sweepAngle;
    final thumbCenter = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    // Thumb circle
    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(thumbCenter, kThumbRadius, thumbPaint);

    // Glass sheen (radial gradient)
    final sheenPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(thumbCenter.dx - 3, thumbCenter.dy - 4),
        kThumbRadius,
        [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(thumbCenter, kThumbRadius, sheenPaint);

    // Subtle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(thumbCenter, kThumbRadius, borderPaint);
  }

  @override
  bool shouldRepaint(LockoutRingPainter oldDelegate) =>
      sweepAngle != oldDelegate.sweepAngle || skyImage != oldDelegate.skyImage;
}
```

- [ ] **Step 4: Fix test imports and run**

Update the test file imports:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_ring_painter.dart';
```

Run:

```bash
fvm flutter test test/presentation/pages/home/components/lockout_duration_ring_test.dart
```

Expected: All 13 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/home/components/lockout_ring_painter.dart \
       test/presentation/pages/home/components/lockout_duration_ring_test.dart
git commit -m "feat: add lockout ring painter with sky-filled arc"
```

---

### Task 3: Duration Ring Widget — gesture handling and image loading

**Files:**
- Create: `lib/presentation/pages/home/components/lockout_duration_ring.dart`

This widget wraps the painter with gesture detection, image preloading, and a glass disc interior.

- [ ] **Step 1: Create the duration ring widget**

Create `lib/presentation/pages/home/components/lockout_duration_ring.dart`:

```dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_ring_painter.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LockoutDurationRing extends HookWidget {
  const LockoutDurationRing({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.minMinutes = 30,
    this.size = 220,
  });

  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;
  final int minMinutes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skyImage = useState<ui.Image?>(null);
    final isDragging = useState(false);

    // Load the sky image once
    useEffect(
      () {
        _loadSkyImage().then((img) => skyImage.value = img);
        return null;
      },
      const [],
    );

    final sweepAngle = durationToSweepAngle(duration);
    final center = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Glass disc interior (behind the ring)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kThumbRadius),
              child: ClipOval(
                child: AppGlassContainer(
                  config: const GlassConfig(cornerRadius: 999),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          // Ring + gesture layer
          GestureDetector(
            onPanStart: (details) {
              isDragging.value = true;
              _handleDrag(details.localPosition, center);
            },
            onPanUpdate: (details) {
              _handleDrag(details.localPosition, center);
            },
            onPanEnd: (_) => isDragging.value = false,
            child: CustomPaint(
              size: Size(size, size),
              painter: LockoutRingPainter(
                sweepAngle: sweepAngle,
                skyImage: skyImage.value,
                trackColor: Colors.white.withValues(alpha: 0.05),
                glowColor: const Color(0xFF5BA3D9).withValues(alpha: 0.1),
                tickColor: Colors.white.withValues(alpha: 0.18),
                thumbColor: const Color(0xFF5BA3D9),
              ),
            ),
          ),
          // Center duration text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  duration.inHours >= 1 ? 'hours' : 'minutes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrag(Offset localPosition, double center) {
    final angle = polarAngleFromPoint(
      localPosition.dx,
      localPosition.dy,
      center,
      center,
    );
    final rawDuration = angleToDuration(angle);
    final snapped = snapDuration(rawDuration, minMinutes: minMinutes);

    if (snapped != duration) {
      HapticFeedback.selectionClick();
      onDurationChanged(snapped);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return minutes == 0 ? '$hours:00' : '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}';
  }

  Future<ui.Image> _loadSkyImage() async {
    final data = await rootBundle.load(Assets.png.backgroundGoback.path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
fvm flutter analyze lib/presentation/pages/home/components/lockout_duration_ring.dart
```

Expected: No errors (warnings acceptable at this stage).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/home/components/lockout_duration_ring.dart
git commit -m "feat: add lockout duration ring widget with drag gesture"
```

---

### Task 4: Activity Chips — square chips with line icons and custom morph

**Files:**
- Create: `lib/presentation/pages/home/components/lockout_activity_chips.dart`
- Create: `test/presentation/pages/home/components/lockout_activity_chips_test.dart`

- [ ] **Step 1: Write widget tests for chip selection behavior**

Create `test/presentation/pages/home/components/lockout_activity_chips_test.dart`:

```dart
import 'package:cloudless/presentation/pages/home/components/lockout_activity_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    String? selected,
    String? customText,
    ValueChanged<String?>? onSelected,
    ValueChanged<String?>? onCustomTextChanged,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: LockoutActivityChips(
          selectedPreset: selected,
          customText: customText,
          onPresetSelected: onSelected ?? (_) {},
          onCustomTextChanged: onCustomTextChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders all 5 preset chips plus custom', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Relax'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    // Custom chip has no text label, just the icon
    expect(find.byType(LockoutActivityChips), findsOneWidget);
  });

  testWidgets('tapping a chip calls onPresetSelected', (tester) async {
    String? result;
    await tester.pumpWidget(buildApp(onSelected: (v) => result = v));

    await tester.tap(find.text('Music'));
    expect(result, 'music');
  });

  testWidgets('tapping selected chip deselects it', (tester) async {
    String? result = 'sport';
    await tester.pumpWidget(buildApp(
      selected: 'sport',
      onSelected: (v) => result = v,
    ));

    await tester.tap(find.text('Sport'));
    expect(result, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/presentation/pages/home/components/lockout_activity_chips_test.dart
```

Expected: Compilation error — `LockoutActivityChips` not found.

- [ ] **Step 3: Create the activity chips widget**

Create `lib/presentation/pages/home/components/lockout_activity_chips.dart`:

```dart
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Preset activity definitions: key → (label, icon builder).
const _presets = <String, ({String label, IconData icon})>{
  'sport': (label: 'Sport', icon: Icons.directions_run_rounded),
  'music': (label: 'Music', icon: Icons.music_note_rounded),
  'friends': (label: 'Friends', icon: Icons.people_outline_rounded),
  'relax': (label: 'Relax', icon: Icons.spa_outlined),
  'studying': (label: 'Study', icon: Icons.menu_book_rounded),
};

class LockoutActivityChips extends HookWidget {
  const LockoutActivityChips({
    super.key,
    required this.selectedPreset,
    required this.customText,
    required this.onPresetSelected,
    required this.onCustomTextChanged,
  });

  final String? selectedPreset;
  final String? customText;
  final ValueChanged<String?> onPresetSelected;
  final ValueChanged<String?> onCustomTextChanged;

  @override
  Widget build(BuildContext context) {
    final isCustomExpanded = useState(false);
    final customController = useTextEditingController(text: customText);
    final customFocus = useFocusNode();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ..._presets.entries.map((e) => _PresetChip(
              label: e.value.label,
              icon: e.value.icon,
              isSelected: selectedPreset == e.key,
              onTap: () {
                // Collapse custom if open
                if (isCustomExpanded.value) {
                  isCustomExpanded.value = false;
                  customController.clear();
                  onCustomTextChanged(null);
                }
                // Toggle selection
                onPresetSelected(selectedPreset == e.key ? null : e.key);
              },
            )),
        _CustomChip(
          isExpanded: isCustomExpanded.value,
          controller: customController,
          focusNode: customFocus,
          onTap: () {
            if (!isCustomExpanded.value) {
              isCustomExpanded.value = true;
              onPresetSelected(null);
              // Focus after the animation frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                customFocus.requestFocus();
              });
            }
          },
          onChanged: (text) {
            onCustomTextChanged(text.isEmpty ? null : text);
          },
          onClear: () {
            isCustomExpanded.value = false;
            customController.clear();
            onCustomTextChanged(null);
          },
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = MainColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: label.length > 5 ? 82 : 76,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accent : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? accent : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({
    required this.isExpanded,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.onClear,
  });

  final bool isExpanded;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExpanded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: isExpanded ? 150 : 42,
        height: 42,
        decoration: BoxDecoration(
          color: isExpanded
              ? MainColors.accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded
                ? MainColors.accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: isExpanded
            ? Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: MainColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: 20,
                      onChanged: onChanged,
                      style: TextStyle(
                        fontSize: 13,
                        color: MainColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
fvm flutter test test/presentation/pages/home/components/lockout_activity_chips_test.dart
```

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/home/components/lockout_activity_chips.dart \
       test/presentation/pages/home/components/lockout_activity_chips_test.dart
git commit -m "feat: add lockout activity chips with custom morph animation"
```

---

### Task 5: Bottom Sheet Assembly — glass sheet combining all components

**Files:**
- Create: `lib/presentation/pages/home/components/lockout_bottom_sheet.dart`
- Create: `test/presentation/pages/home/components/lockout_bottom_sheet_test.dart`

- [ ] **Step 1: Write widget test for the bottom sheet**

Create `test/presentation/pages/home/components/lockout_bottom_sheet_test.dart`:

```dart
import 'package:cloudless/presentation/pages/home/components/lockout_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required void Function(
            ({Duration? duration, String? actionText, bool nfcScan})?)
        onResult,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await LockoutBottomSheet.show(context);
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('sheet shows Go Back button and NFC link', (tester) async {
    await tester.pumpWidget(buildApp(onResult: (_) {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Go Back'), findsWidgets); // title + CTA
    expect(find.text('Scan Tag'), findsOneWidget);
  });

  testWidgets('tapping Scan Tag returns nfcScan true', (tester) async {
    ({Duration? duration, String? actionText, bool nfcScan})? result;
    await tester.pumpWidget(buildApp(onResult: (r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Tag'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.nfcScan, isTrue);
    expect(result!.duration, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/presentation/pages/home/components/lockout_bottom_sheet_test.dart
```

Expected: Compilation error — `LockoutBottomSheet` not found.

- [ ] **Step 3: Create the bottom sheet widget**

Create `lib/presentation/pages/home/components/lockout_bottom_sheet.dart`:

```dart
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_activity_chips.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_duration_ring.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Minimum lockout duration in minutes.
/// Override at build time: `--dart-define=MIN_LOCKOUT_MINUTES=1`
const _kMinLockoutMinutes = int.fromEnvironment(
  'MIN_LOCKOUT_MINUTES',
  defaultValue: 30,
);

class LockoutBottomSheet extends HookWidget {
  const LockoutBottomSheet({super.key});

  /// Shows the lockout bottom sheet and returns the user's selection.
  ///
  /// Returns `null` if dismissed. When [nfcScan] is `true`, [duration] and
  /// [actionText] are `null`.
  static Future<({Duration? duration, String? actionText, bool nfcScan})?>
      show(BuildContext context) {
    return showModalBottomSheet<
        ({Duration? duration, String? actionText, bool nfcScan})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x800A0A0A),
      builder: (_) => const LockoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = useState(const Duration(hours: 1));
    final selectedPreset = useState<String?>(null);
    final customText = useState<String?>(null);

    final isValid = duration.value.inMinutes >= _kMinLockoutMinutes;

    // Resolve the action text from preset or custom input
    String? resolveActionText() {
      if (customText.value != null) return customText.value;
      if (selectedPreset.value == null) return null;
      // Capitalize the preset key
      final key = selectedPreset.value!;
      return key[0].toUpperCase() + key.substring(1);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AppGlassContainer(
        config: const GlassConfig(cornerRadius: 24),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'GO BACK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 24),
                // Duration ring
                LockoutDurationRing(
                  duration: duration.value,
                  onDurationChanged: (d) => duration.value = d,
                  minMinutes: _kMinLockoutMinutes,
                ),
                const SizedBox(height: 28),
                // Activity chips
                LockoutActivityChips(
                  selectedPreset: selectedPreset.value,
                  customText: customText.value,
                  onPresetSelected: (key) {
                    selectedPreset.value = key;
                    customText.value = null;
                  },
                  onCustomTextChanged: (text) {
                    customText.value = text;
                    selectedPreset.value = null;
                  },
                ),
                const SizedBox(height: 24),
                // Go Back CTA
                CallToAction.primary.filled(
                  action: isValid
                      ? () => Navigator.of(context).pop((
                            duration: duration.value,
                            actionText: resolveActionText(),
                            nfcScan: false,
                          ))
                      : null,
                  label: const Text('Go Back'),
                ),
                const SizedBox(height: 14),
                // NFC link
                GestureDetector(
                  onTap: () => Navigator.of(context).pop((
                    duration: null,
                    actionText: null,
                    nfcScan: true,
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text.rich(
                      TextSpan(
                        text: 'At a venue? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        children: [
                          TextSpan(
                            text: 'Scan Tag',
                            style: TextStyle(
                              color: MainColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
fvm flutter test test/presentation/pages/home/components/lockout_bottom_sheet_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/home/components/lockout_bottom_sheet.dart \
       test/presentation/pages/home/components/lockout_bottom_sheet_test.dart
git commit -m "feat: add glass lockout bottom sheet with ring and chips"
```

---

### Task 6: Integration — wire up HomeLockoutButton and remove old dialog

**Files:**
- Modify: `lib/presentation/pages/home/components/home_lockout_button.dart:5,26`
- Delete: `lib/presentation/pages/home/components/manual_lockout_dialog.dart`

- [ ] **Step 1: Update HomeLockoutButton to use the new bottom sheet**

In `lib/presentation/pages/home/components/home_lockout_button.dart`:

Replace the import (line 5):

```dart
// Before:
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';

// After:
import 'package:cloudless/presentation/pages/home/components/lockout_bottom_sheet.dart';
```

Replace the dialog call (line 26):

```dart
// Before:
final result = await ManualLockoutDialog.show(context);

// After:
final result = await LockoutBottomSheet.show(context);
```

No other changes needed — the return type is identical.

- [ ] **Step 2: Delete the old dialog file**

```bash
rm lib/presentation/pages/home/components/manual_lockout_dialog.dart
```

- [ ] **Step 3: Verify no remaining references to ManualLockoutDialog**

```bash
fvm dart run grep -r 'ManualLockoutDialog' lib/
```

Expected: No matches. If any references remain, update them to use `LockoutBottomSheet`.

- [ ] **Step 4: Run full analyzer and tests**

```bash
fvm flutter analyze --no-fatal-warnings && fvm flutter test
```

Expected: Analysis clean. All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/home/components/home_lockout_button.dart \
       test/
git rm lib/presentation/pages/home/components/manual_lockout_dialog.dart
git commit -m "feat: replace lockout dialog with glass bottom sheet

Replaces the old ManualLockoutDialog (dual Cupertino pickers, emoji chips)
with the new LockoutBottomSheet featuring a sky-filled drag ring,
square activity chips with line icons, and a custom chip morph animation."
```

---

### Task 7: Manual Smoke Test

This task is not automated — it requires running the app on a device or simulator.

- [ ] **Step 1: Run the app**

```bash
fvm flutter run --flavor production
```

- [ ] **Step 2: Verify bottom sheet**

1. Tap the GoBack button on the home screen
2. Verify: glass bottom sheet slides up with drag ring at 1:00 default
3. Drag the thumb clockwise — duration increases, sky fills the arc
4. Drag below 30 min — thumb stops, cannot go lower
5. Drag to 10:00 — full ring fills with sky
6. Verify haptic feedback on each snap point

- [ ] **Step 3: Verify activity chips**

1. Tap "Sport" — chip highlights in accent blue
2. Tap "Sport" again — deselects
3. Tap custom (pencil) chip — expands into text field
4. Type a custom activity — preset chips deselect
5. Tap X on custom field — collapses back to pencil
6. Tap a preset while custom is open — custom collapses

- [ ] **Step 4: Verify submit and NFC**

1. With 2:00 selected and "Sport" chosen, tap "Go Back"
2. Verify lockout starts correctly with 2-hour duration and "Sport" action text
3. Repeat: open sheet, tap "Scan Tag" — verify NFC flow launches

- [ ] **Step 5: Verify dismissal**

1. Open sheet, drag it down — dismisses, no lockout starts
2. Open sheet, tap scrim — dismisses
