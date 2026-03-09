import 'package:cloudless/core/features/lockout/data/dtos/lockout_monthly_summary_dto.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_lockout_monthly_summary_provider.g.dart';

@riverpod
Future<Result<LockoutMonthlySummaryDto?>> getLockoutMonthlySummary(
  Ref ref, {
  required String userId,
  required int year,
  required int month,
}) async {
  ref.cacheFor(const Duration(minutes: 5));

  final service = ref.watch(lockoutSessionServiceProvider);
  return service.getMonthlySummary(userId: userId, year: year, month: month);
}
