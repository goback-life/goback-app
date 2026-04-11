import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:cloudless/core/features/connection/domain/providers/validate_invite_code_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef ValidateInviteCodeCallback =
    Future<Result<InviteValidationResult>> Function(String);

ValidateInviteCodeCallback useValidateInviteCode(WidgetRef ref) {
  return useCallback((String inviteCode) {
    return ref.read(validateInviteCodeProvider(inviteCode).future);
  }, [ref]);
}
