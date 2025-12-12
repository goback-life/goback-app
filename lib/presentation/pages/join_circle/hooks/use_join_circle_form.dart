import 'package:cloudless/core/features/connection/domain/hooks/use_join_circle.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_validate_invite_code.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef JoinCircleFormResult = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<bool> isSubmitting,
  ValueNotifier<bool> isLoadingOverlay,
});

enum JoinCircleFormKey { inviteCode }

extension JoinCircleFormKeyExtension on JoinCircleFormKey {
  String get value => switch (this) {
    JoinCircleFormKey.inviteCode => 'inviteCode',
  };
}

JoinCircleFormResult useJoinCircleForm(WidgetRef ref) {
  final validateInviteCode = useValidateInviteCode(ref);
  final joinCircle = useJoinCircle(ref);
  final isLoadingOverlay = useState<bool>(false);

  final formResult = useForm<bool>(
    controls: {
      JoinCircleFormKey.inviteCode.value: FormerControl<String>(
        validators: [
          FormerValidators.required(),
          FormerValidators.minLength(6),
          FormerValidators.maxLength(6),
        ],
      ),
    },
    onSubmit: (values) async {
      final inviteCode = values[JoinCircleFormKey.inviteCode.value] as String;

      final validationResult = await validateInviteCode(inviteCode);

      return validationResult.fold((inviteValidationResult) async {
        return inviteValidationResult.when(
          valid: (creatorProfile) async {
            final username = creatorProfile['username'] as String? ?? 'Unknown';

            final shouldJoin = await MainAlert.showFull<bool>(
              context: ref.context,
              title: translator.translate(
                'components.alert.join_circle.title',
                arguments: {'username': username},
              ),
              content: Text(
                translator.translate('components.alert.join_circle.content'),
              ),
              primaryButtonText: translator.translate(
                'components.alert.join_circle.confirm',
              ),
              secondaryButtonText: translator.translate(
                'components.alert.join_circle.cancel',
              ),
              primaryButtonType: CallToActionType.primary,
              onPrimaryPressed: () => Navigator.of(ref.context).pop(true),
              onSecondaryPressed: () => Navigator.of(ref.context).pop(false),
            );

            if (shouldJoin == true) {
              isLoadingOverlay.value = true;
              final joinResult = await joinCircle(inviteCode);
              isLoadingOverlay.value = false;
              return joinResult.fold(
                (success) => Result.success(success),
                (error) => Result.failure(error),
              );
            }

            return Result.success(false);
          },
          invalid: (errorMessage) {
            return Result.failure(Exception(errorMessage));
          },
        );
      }, (error) => Result.failure(error));
    },
    onSuccess: (success) async {
      logger.info('Join circle success: $success');

      if (success) {
        ref.invalidate(getCircleMembersProvider);
        router.pop();
      }
    },
    onFailure: (form, error) {
      logger.error('Join circle failed', exception: error);

      form.control(JoinCircleFormKey.inviteCode.value).setErrors({
        'invalid': true,
      });

      String displayMessage;
      final errorMessage = error.toString();

      if (errorMessage.contains('self') || errorMessage.contains('stesso')) {
        displayMessage = translator.translate(
          'pages.join_circle.error.connect_yourself',
        );
      } else if (errorMessage.contains('already') ||
          errorMessage.contains('già')) {
        displayMessage = translator.translate(
          'pages.join_circle.error.already_in_circle',
        );
      } else {
        displayMessage = translator.translate(
          'pages.join_circle.error.invalid_code',
        );
      }

      MainAlert.showError(
        context: ref.context,
        title: translator.translate('pages.join_circle.error.title'),
        content: displayMessage,
      );
    },
  );

  useEffect(() {
    final inviteCodeControl = formResult.form.control(
      JoinCircleFormKey.inviteCode.value,
    );
    final sub = inviteCodeControl.valueChanges.listen((value) {
      if (inviteCodeControl.hasError('invalid')) {
        inviteCodeControl
          ..setErrors({})
          ..updateValueAndValidity();
      }
    });

    return sub.cancel;
  }, const []);

  return (
    form: formResult.form,
    submit: formResult.submit,
    isSubmitting: formResult.isSubmitting,
    isLoadingOverlay: isLoadingOverlay,
  );
}
