import 'package:cloudless/core/features/lockout/data/services/lockout_live_activity_service.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lockout_live_activity_service_provider.g.dart';

@Riverpod(keepAlive: true)
LockoutLiveActivityService lockoutLiveActivityService(Ref ref) {
  final service = LockoutLiveActivityService();
  service.init();
  return service;
}
