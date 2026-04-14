# Goback Score v2 — Multi-Signal Composite Score

## Problem

The current goback score uses battery drain as a single proxy for phone disconnection. Two gaps:

1. **Charging during lockout**: when `batteryEnd > batteryStart`, drain clamps to 0, giving a perfect score. This is wrong — charging tells us nothing about disconnection.
2. **Single signal**: battery drain alone can't distinguish "phone on nightstand" from "phone plugged in and actively used."

## Philosophy

The score measures **mental disconnection** — was the user truly disengaged from their phone? Not "was the phone untouched."

- Charging while hiking = high score (disconnected)
- Charging while scrolling = low score (not disconnected)
- Meditating with phone off = high score (0 steps is fine)

## Signal Model

Three input signals:

| Signal | Source | Permission | What it measures |
|--------|--------|------------|------------------|
| Battery drain | `battery_plus` (existing) | None | Phone usage via power consumption |
| Charging state | `battery_plus` (existing) | None | Whether battery data is trustworthy |
| Step count | `pedometer` package (new) | `NSMotionUsageDescription` (iOS), `ACTIVITY_RECOGNITION` (Android) | Physical activity away from phone |

### Signal roles

- **Battery drain** — primary quality signal when reliable (no charging detected)
- **Charging state** — confidence modifier; when true, battery data is degraded and the system leans on steps
- **Step count** — one-way boost only; steps corroborate disconnection, but 0 steps is neutral (meditation, reading, napping are all valid disconnection)

## Formula

### Time multiplier (unchanged)

```
timeMultiplier = 0.7 + 0.3 * (minutes / 240).clamp(0, 1)
```

0 min = 0.7x, 240 min (4 hrs) = 1.0x asymptote.

### Step bonus

```
stepBonus = steps != null
    ? 0.3 * ((steps / durationHours) / 3000).clamp(0, 1)
    : 0.0
```

- 0 steps or null → 0.0 (neutral, never a penalty)
- 3,000 steps/hr (brisk walk) → 0.3 (maximum boost)

### Battery quality (unchanged formula)

```
drainPerHour = max(0, batteryStart - batteryEnd) / durationHours
batteryQuality = (1.0 - (drainPerHour - 2.0) / 13.0).clamp(0, 1)
```

- 2%/hr (idle) = 1.0
- 15%/hr (heavy use) = 0.0

### Composite quality by case

| Case | Condition | Quality formula |
|------|-----------|----------------|
| 1 | Battery available, no charging | `(batteryQuality + stepBonus).clamp(0, 1)` |
| 2a | Battery available, was charging, has steps | `(0.7 + stepBonus).clamp(0, 1)` |
| 2b | Battery available, was charging, no steps | `batteryQuality.clamp(0, 0.7)` |
| 3 | No battery data | `(0.7 + stepBonus).clamp(0, 1)` |

### Final score

```
score = (quality * 100 * timeMultiplier).round().clamp(0, 100)
```

## Behavioral examples

| Scenario | Approx. score |
|----------|---------------|
| Low drain, no charging, lots of steps | 90–100 |
| Low drain, no charging, no steps | 70–100 |
| Charged, went for a walk | 70–100 |
| Charged, no steps, low drain | ≤70 |
| Charged, no steps, high drain | Low (using phone while charging) |
| No battery data, lots of steps | 70–100 |
| No battery data, no steps | ~49–70 (time-only) |
| Heavy drain, no charging, no steps | 0–30 |

## Data Capture

### Battery charging state

Already available via `battery_plus`. Subscribe to `onBatteryStateChanged` stream during lockout:

- On lockout start: subscribe to stream, init `wasChargingDuringLockout = false`
- On any `BatteryState.charging` or `BatteryState.full` event: set flag to `true`
- On lockout end: unsubscribe, pass flag to calculator
- No background task needed — the stream fires while the app process is alive

### Step count

New dependency: `pedometer` package. Uses `CMPedometer` (iOS) / `TYPE_STEP_COUNTER` (Android).

- On lockout start: record start timestamp
- On lockout end: query `Pedometer.getStepCount(startTime, endTime)` for total steps in range
- No background task needed — pedometer APIs support historical range queries
- If permission denied: `steps = null`, `stepBonus = 0.0` (no penalty)

### Permission UX

Pedometer permission prompt triggers on first lockout completion. If denied, the system silently falls back. No blocking flow, no repeated prompts.

## Database Changes

### New columns on `lockout_sessions`

| Column | Type | Nullable | Default | Purpose |
|--------|------|----------|---------|---------|
| `battery_was_charging` | `BOOLEAN` | YES | `null` | Whether charging was detected during lockout |
| `step_count` | `SMALLINT` | YES | `null` | Steps recorded during lockout |

Migration file: `019_lockout_score_signals.sql`

### No changes to

- `goback_score` column (still SMALLINT, same 0–100 range)
- Stats DTOs / RPC functions (they aggregate `goback_score`, unchanged type)
- `lockout_completed_log` (copies score, not raw inputs)
- RLS policies (same row-level access)

## Model Changes

- `LockoutSessionDto` / `LockoutSessionModel` — add `batteryWasCharging` (bool?) and `stepCount` (int?) fields
- `GobackScoreCalculator.calculate()` — add `steps` (int?) and `wasCharging` (bool) parameters
- `LockoutSessionService.updateScore()` — persist `battery_was_charging` and `step_count` alongside score
- `ManualLockoutStorable` — add `wasChargingDuringLockout` (bool)

## New dependency

- `pedometer` (or `pedometer_2`) — Flutter plugin for step counting
- iOS: add `NSMotionUsageDescription` to Info.plist
- Android: add `ACTIVITY_RECOGNITION` permission to AndroidManifest.xml
