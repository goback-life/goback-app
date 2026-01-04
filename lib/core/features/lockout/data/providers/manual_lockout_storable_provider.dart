import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_lockout_storable_provider.g.dart';

@Riverpod(keepAlive: true)
ManualLockoutStorable manualLockoutStorable(Ref ref) {
  return ManualLockoutStorable();
}

