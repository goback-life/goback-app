import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ConnectionRequestsData {
  const ConnectionRequestsData({
    required this.outgoingRequests,
    required this.incomingRequests,
    required this.isLoading,
    required this.send,
    required this.respond,
    required this.cancel,
    required this.refresh,
  });

  final List<ConnectionRequestModel> outgoingRequests;
  final List<ConnectionRequestModel> incomingRequests;
  final bool isLoading;
  final Future<Result<String>> Function(String receiverId) send;
  final Future<Result<void>> Function(String requestId, {required bool accept})
      respond;
  final Future<Result<void>> Function(String requestId) cancel;
  final void Function() refresh;
}

ConnectionRequestsData useConnectionRequests(WidgetRef ref) {
  final asyncOutgoing = ref.watch(getOutgoingRequestsProvider);
  final asyncIncoming = ref.watch(getIncomingRequestsProvider);

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

  final incomingRequests = useMemoized(() {
    return asyncIncoming.when(
      data: (result) => result.fold(
        (list) => list,
        (_) => <ConnectionRequestModel>[],
      ),
      loading: () => <ConnectionRequestModel>[],
      error: (_, __) => <ConnectionRequestModel>[],
    );
  }, [asyncIncoming]);

  final isLoading = asyncOutgoing.isLoading || asyncIncoming.isLoading;

  void _refreshAll() {
    ref.invalidate(getOutgoingRequestsProvider);
    ref.invalidate(getIncomingRequestsProvider);
  }

  final send = useCallback((String receiverId) async {
    final result = await ref.read(
      sendConnectionRequestProvider(receiverId).future,
    );
    result.fold((_) => _refreshAll(), (_) {});
    return result;
  }, [ref]);

  final respond = useCallback((
    String requestId, {
    required bool accept,
  }) async {
    final result = await ref.read(
      respondToConnectionRequestProvider(requestId, accept: accept).future,
    );
    result.fold((_) => _refreshAll(), (_) {});
    return result;
  }, [ref]);

  final cancel = useCallback((String requestId) async {
    final result = await ref.read(
      cancelConnectionRequestProvider(requestId).future,
    );
    result.fold((_) => _refreshAll(), (_) {});
    return result;
  }, [ref]);

  return ConnectionRequestsData(
    outgoingRequests: outgoingRequests,
    incomingRequests: incomingRequests,
    isLoading: isLoading,
    send: send,
    respond: respond,
    cancel: cancel,
    refresh: _refreshAll,
  );
}
