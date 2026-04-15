import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_circle_leaderboard_provider.g.dart';

@Riverpod(keepAlive: false)
class GetCircleLeaderboard extends _$GetCircleLeaderboard {
  @override
  Future<Result<List<LeaderboardEntryDto>>> build() async {
    final service = ref.watch(connectionServiceProvider);
    return service.getCircleLeaderboard();
  }
}
