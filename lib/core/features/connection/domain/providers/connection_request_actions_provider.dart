import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_request_actions_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<String>> sendConnectionRequest(
  Ref ref,
  String receiverId,
) async {
  final service = ref.watch(connectionServiceProvider);
  return await service.sendConnectionRequest(receiverId);
}

@Riverpod(keepAlive: false)
Future<Result<void>> respondToConnectionRequest(
  Ref ref,
  String requestId, {
  required bool accept,
}) async {
  final service = ref.watch(connectionServiceProvider);
  return await service.respondToConnectionRequest(
    requestId,
    accept: accept,
  );
}

@Riverpod(keepAlive: false)
Future<Result<void>> cancelConnectionRequest(
  Ref ref,
  String requestId,
) async {
  final service = ref.watch(connectionServiceProvider);
  return await service.cancelConnectionRequest(requestId);
}
