import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_limit_usage_storable_provider.g.dart';

@Riverpod(keepAlive: true)
TimeLimitUsageStorable timeLimitUsageStorable(Ref ref) {
  return TimeLimitUsageStorable();
}
