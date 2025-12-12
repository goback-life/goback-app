import 'package:cloudless/core/features/connection/domain/providers/remove_connection_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef RemoveConnectionCallback = Future<Result<bool>> Function(String);

RemoveConnectionCallback useRemoveConnection(WidgetRef ref) {
  return useCallback((String userId) {
    return ref.read(removeConnectionProvider(userId).future);
  }, [ref]);
}
