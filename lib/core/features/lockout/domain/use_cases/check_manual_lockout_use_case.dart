import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Checks if the user is currently locked out manually
class CheckManualLockoutUseCase implements UseCaseContract<bool> {
  const CheckManualLockoutUseCase({required this.storable});

  final ManualLockoutStorable storable;

  @override
  Future<bool> execute() async {
    // Note: We intentionally do NOT clear expired lockouts here.
    // The lockout data (including sessionId) must persist until the user
    // either creates a post or skips on the lockout_complete screen.
    // Clearing is handled by lockout_complete_view and use_post_creation.
    return await storable.isLockedOut();
  }
}

