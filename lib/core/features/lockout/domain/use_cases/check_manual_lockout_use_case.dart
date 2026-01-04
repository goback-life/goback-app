import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Checks if the user is currently locked out manually
class CheckManualLockoutUseCase implements UseCaseContract<bool> {
  const CheckManualLockoutUseCase({required this.storable});

  final ManualLockoutStorable storable;

  @override
  Future<bool> execute() async {
    final isLockedOut = await storable.isLockedOut();

    // If lockout has expired, clear it
    if (!isLockedOut) {
      final lockoutEnd = await storable.getLockoutEnd();
      if (lockoutEnd != null) {
        // Lockout expired, clear it
        await storable.clearLockout();
      }
    }

    return isLockedOut;
  }
}

