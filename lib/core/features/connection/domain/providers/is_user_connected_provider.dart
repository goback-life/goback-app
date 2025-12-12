import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_user_connected_provider.g.dart';

@riverpod
Future<Result<bool>> isUserConnected(Ref ref, String userId) async {
  final connectionService = ref.watch(connectionServiceProvider);
  return await connectionService.isUserConnected(userId);
}
