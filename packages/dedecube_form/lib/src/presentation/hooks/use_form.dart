import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_typedef.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:flutter/foundation.dart';

/// A hook that manages the state and logic of a form.
///
/// This hook initializes a [FormerGroup] using the provided [controls] and optional
/// synchronous and asynchronous validators. It returns a [FormResult] record containing:
/// - the form group (form)
/// - an asynchronous submission function (submit)
/// - a [ValueNotifier] for the submission result (result)
/// - a [ValueNotifier] indicating whether the form is being submitted (isSubmitting)
///
/// The hook also takes callbacks for successful ([onSuccess]) or failed ([onFailure])
/// submissions. If [markAsTouchedOnSubmit] is true, all controls will be marked as touched
/// when the form is submitted and found invalid.
FormResult<T> useForm<T>({
  required FormControls controls,
  required FormSubmitHandler<T> onSubmit,
  FormSuccessHandler<T>? onSuccess,
  FormFailureHandler? onFailure,
  bool markAsTouchedOnSubmit = true,
  List<FormerGroupValidator>? validators,
  List<FormerAsyncGroupValidator>? asyncValidators,
  int asyncValidatorsDebounceTime = 250,
}) {
  // Create and memoize the FormerGroup instance using the provided controls and validators.
  final form = useMemoized(
    () => FormerGroup(
      controls,
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorsDebounceTime: asyncValidatorsDebounceTime,
    ),
    const [],
  );

  // State notifier for tracking whether the form is currently submitting.
  final isSubmitting = useState(false);

  // State notifier to hold the submission result.
  final result = useState<T?>(null);

  // Submit callback encapsulating the submission workflow.
  final submit = useCallback(() async {
    // Prevent multiple simultaneous submissions.
    if (isSubmitting.value) {
      return;
    }

    // Validate the form. Optionally mark all fields as touched to trigger validation messages.
    if (!form.valid) {
      if (markAsTouchedOnSubmit) {
        form.markAllAsTouched();
      }
      return;
    }

    // Build a map of current control values.
    final values = <String, dynamic>{};
    controls.forEach((key, _) {
      values[key] = form.control<dynamic>(key).value;
    });

    // Set the submitting flag and attempt form submission.
    isSubmitting.value = true;
    try {
      final submitResult = await onSubmit(values);

      // Process the result:
      // On success, set [result] and invoke [onSuccess] callback.
      // On failure, trigger the [onFailure] callback.
      submitResult.fold(
        (successValue) {
          result.value = successValue;
          onSuccess?.call(successValue);
        },
        (error) {
          onFailure?.call(form, error);
        },
      );
    } finally {
      // Reset the submitting flag regardless of the outcome.
      isSubmitting.value = false;
    }
  }, [
    form,
    controls,
    onSubmit,
    onSuccess,
    onFailure,
    isSubmitting,
    markAsTouchedOnSubmit,
  ]);

  return (
    form: form,
    submit: submit,
    result: result,
    isSubmitting: isSubmitting
  );
}
