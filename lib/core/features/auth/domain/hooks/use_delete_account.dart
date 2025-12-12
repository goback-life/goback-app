import 'package:cloudless/core/features/auth/domain/providers/delete_account_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef DeleteAccountCallback = Future<Result<void>> Function();

DeleteAccountCallback useDeleteAccount(WidgetRef ref) {
  return useCallback(() {
    return ref.read(deleteAccountProvider.future);
  }, [ref]);
}
