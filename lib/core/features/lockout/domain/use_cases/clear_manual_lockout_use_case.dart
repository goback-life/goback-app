import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Clears the manual lockout
class ClearManualLockoutUseCase implements UseCaseContract<void> {
  const ClearManualLockoutUseCase({required this.storable});

  final ManualLockoutStorable storable;

  @override
  Future<void> execute() async {
    await storable.clearLockout();
  }
}
