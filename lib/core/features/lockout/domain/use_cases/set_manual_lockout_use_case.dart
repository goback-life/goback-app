import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Sets a manual lockout for the specified duration
class SetManualLockoutUseCase implements UseCaseContract<void> {
  const SetManualLockoutUseCase({
    required this.storable,
    required this.duration,
    this.sessionId,
    this.batteryAtStart,
  });

  final ManualLockoutStorable storable;
  final Duration duration;
  final String? sessionId;
  final int? batteryAtStart;

  @override
  Future<void> execute() async {
    final now = DateTime.now();
    final lockoutEnd = now.add(duration);

    await storable.setLockoutData(
      lockoutEndTimestamp: lockoutEnd,
      lockoutStartTimestamp: now,
      lockoutSessionId: sessionId,
      batteryAtStart: batteryAtStart,
    );
  }
}
