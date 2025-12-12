import 'package:cloudless/core/features/time_limit/data/providers/time_limit_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/data/providers/time_limit_usage_storable_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/models/time_limit_model.dart';
import 'package:cloudless/core/features/time_limit/domain/use_cases/get_time_limit_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_time_limit_provider.g.dart';

@Riverpod(keepAlive: false)
Future<TimeLimitModel> getTimeLimit(Ref ref) async {
  final useCase = GetTimeLimitUseCase(
    storable: ref.watch(timeLimitStorableProvider),
    usageStorable: ref.watch(timeLimitUsageStorableProvider),
  );
  return useCase.execute();
}
