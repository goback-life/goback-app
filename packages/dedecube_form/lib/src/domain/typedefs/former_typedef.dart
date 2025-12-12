import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/presentation/hooks/use_form.dart';
import 'package:flutter/foundation.dart';

/// A type alias for the map of form controls.
///
/// Each key in the [FormControls] map represents the name of a control, and
/// the corresponding value is a [FormerControl] object that manages the state
/// for that control.
typedef FormControls = Map<String, FormerControl<dynamic>>;

/// A function type for handling form submissions.
///
/// The onSubmit function is passed the current values of the form as a
/// [Map] (with control names as keys and their values as the corresponding values)
/// and returns a [FutureResult] of type [T]. The [FutureResult] encapsulates either
/// a successful result or an error.
typedef FormSubmitHandler<T> = FutureResult<T> Function(
    Map<String, dynamic> values);

/// A function type for handling successful form submissions.
///
/// When the form submission is successful, this callback is invoked with the
/// resulting value of type [T].
typedef FormSuccessHandler<T> = void Function(T result);

/// A function type for handling failed form submissions.
///
/// When the form submission fails, this callback is invoked with the current
/// form [FormerGroup] and the [Exception] that caused the failure.
typedef FormFailureHandler = void Function(FormerGroup form, Exception error);

/// The result type returned by the [useForm] hook.
///
/// The [FormResult] is a record that contains:
/// • form: the instance of [FormerGroup] representing the form state.
/// • submit: an asynchronous callback that triggers form submission.
/// • result: a [ValueNotifier] that holds the submission result (or null if not submitted yet).
/// • isSubmitting: a [ValueNotifier] representing the submission state.
typedef FormResult<T> = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<T?> result,
  ValueNotifier<bool> isSubmitting,
});
