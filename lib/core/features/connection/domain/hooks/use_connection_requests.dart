import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ConnectionRequestsData {
  const ConnectionRequestsData({
    required this.outgoingRequests,
    required this.isLoading,
    required this.send,
    required this.respond,
    required this.cancel,
    required this.refresh,
  });

  final List<ConnectionRequestModel> outgoingRequests;
  final bool isLoading;
  final Future<Result<String>> Function(String receiverId) send;
  final Future<Result<void>> Function(String requestId, {required bool accept})
      respond;
  final Future<Result<void>> Function(String requestId) cancel;
  final void Function() refresh;
}

ConnectionRequestsData useConnectionRequests(WidgetRef ref) {
  final asyncOutgoing = ref.watch(getOutgoingRequestsProvider);

  final outgoingRequests = useMemoized(() {
    return asyncOutgoing.when(
      data: (result) => result.fold(
        (list) => list,
        (_) => <ConnectionRequestModel>[],
      ),
      loading: () => <ConnectionRequestModel>[],
      error: (_, __) => <ConnectionRequestModel>[],
    );
  }, [asyncOutgoing]);

  final isLoading = asyncOutgoing.isLoading;

  final send = useCallback((String receiverId) async {
    final result = await ref.read(
      sendConnectionRequestProvider(receiverId).future,
    );
    // Refresh outgoing list after sending
    result.fold(
      (_) => ref.invalidate(getOutgoingRequestsProvider),
      (_) {},
    );
    return result;
  }, [ref]);

  final respond = useCallback((
    String requestId, {
    required bool accept,
  }) async {
    final result = await ref.read(
      respondToConnectionRequestProvider(requestId, accept: accept).future,
    );
    result.fold(
      (_) => ref.invalidate(getOutgoingRequestsProvider),
      (_) {},
    );
    return result;
  }, [ref]);

  final cancel = useCallback((String requestId) async {
    final result = await ref.read(
      cancelConnectionRequestProvider(requestId).future,
    );
    result.fold(
      (_) => ref.invalidate(getOutgoingRequestsProvider),
      (_) {},
    );
    return result;
  }, [ref]);

  return ConnectionRequestsData(
    outgoingRequests: outgoingRequests,
    isLoading: isLoading,
    send: send,
    respond: respond,
    cancel: cancel,
    refresh: () => ref.invalidate(getOutgoingRequestsProvider),
  );
}
