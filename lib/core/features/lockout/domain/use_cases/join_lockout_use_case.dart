import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Joins an existing lockout by setting a lockout that ends at the same time as the original.
/// Throws an exception if the lockout has already expired.
///
/// For venue (open-ended) lockouts, stores venue metadata so the local
/// lockout UI shows the correct venue name and count-up timer.
class JoinLockoutUseCase implements UseCaseContract<void> {
  const JoinLockoutUseCase({
    required this.storable,
    required this.lockoutEndTime,
    required this.lockoutSessionId,
    this.batteryAtStart,
    this.isOpenEnded = false,
    this.venueName,
    this.venueTagId,
  });

  final ManualLockoutStorable storable;
  final DateTime lockoutEndTime;
  final String lockoutSessionId;
  final int? batteryAtStart;
  final bool isOpenEnded;
  final String? venueName;
  final String? venueTagId;

  @override
  Future<void> execute() async {
    final now = DateTime.now();
    final remainingDuration = lockoutEndTime.difference(now);

    // Check if lockout has expired (not applicable for open-ended lockouts)
    if (!isOpenEnded && remainingDuration <= Duration.zero) {
      throw Exception('Lockout has expired');
    }

    // Set lockout to end at the same time as the original lockout
    await storable.setLockoutData(
      lockoutEndTimestamp: lockoutEndTime,
      lockoutStartTimestamp: now,
      lockoutSessionId: lockoutSessionId,
      batteryAtStart: batteryAtStart,
      isOpenEnded: isOpenEnded,
      venueName: venueName,
      venueTagId: venueTagId,
    );
  }
}
