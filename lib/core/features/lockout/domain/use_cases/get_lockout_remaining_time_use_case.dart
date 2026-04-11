import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Gets the remaining duration of the manual lockout
/// Returns null if not locked out or lockout has expired
class GetLockoutRemainingTimeUseCase implements UseCaseContract<Duration?> {
  const GetLockoutRemainingTimeUseCase({required this.storable});

  final ManualLockoutStorable storable;

  @override
  Future<Duration?> execute() async {
    final lockoutEnd = await storable.getLockoutEnd();
    if (lockoutEnd == null) {
      return null;
    }

    final now = DateTime.now();
    if (now.isAfter(lockoutEnd)) {
      // Lockout expired, clear it
      await storable.clearLockout();
      return null;
    }

    return lockoutEnd.difference(now);
  }
}
