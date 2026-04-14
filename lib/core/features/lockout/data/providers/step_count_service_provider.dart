import 'package:cloudless/core/features/lockout/data/services/step_count_service.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'step_count_service_provider.g.dart';

@Riverpod(keepAlive: true)
StepCountService stepCountService(Ref ref) {
  return StepCountService();
}
