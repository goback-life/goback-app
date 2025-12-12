import 'package:cloudless/core/features/connection/domain/providers/join_circle_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef JoinCircleCallback = Future<Result<bool>> Function(String);

JoinCircleCallback useJoinCircle(WidgetRef ref) {
  return useCallback((String inviteCode) {
    return ref.read(joinCircleProvider(inviteCode).future);
  }, [ref]);
}
