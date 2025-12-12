import 'package:cloudless/core/features/connection/domain/providers/create_invite_code_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef CreateInviteCodeCallback =
    Future<Result<String>> Function({int expiryHours});

CreateInviteCodeCallback useCreateInviteCode(WidgetRef ref) {
  return useCallback(({int expiryHours = 72}) {
    return ref.read(createInviteCodeProvider(expiryHours: expiryHours).future);
  }, [ref]);
}
