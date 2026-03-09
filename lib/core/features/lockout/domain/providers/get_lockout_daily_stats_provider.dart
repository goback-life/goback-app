import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_lockout_daily_stats_provider.g.dart';

@riverpod
Future<Result<List<LockoutDailyStatsDto>>> getLockoutDailyStats(
  Ref ref, {
  required String userId,
  required DateTime weekStart,
}) async {
  ref.cacheFor(const Duration(minutes: 5));

  final service = ref.watch(lockoutSessionServiceProvider);
  return service.getDailyStats(userId: userId, weekStart: weekStart);
}
