import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `FormerControlValidator` that provides a convenient method
/// to convert a `FormerControlValidator` into a `reactive.Validator`.
///
/// This extension adds the `toReactive` getter, which creates a
/// `reactive.Validator` instance from the current `FormerControlValidator`,
/// allowing it to be used seamlessly within the reactive forms framework.
///
/// Example:
/// ```dart
/// final controlValidator = (FormerControl<String> control) {
///   // Your validation logic...
///   return null;
/// };
///
/// final reactiveValidator = controlValidator.toReactive;
/// ```
extension ReactiveValidatorAdapter<T> on FormerControlValidator<T> {
  reactive.Validator<T> toReactive() => _ReactiveWrappedValidator<T>(this);
}

/// A wrapper that adapts a `FormerControlValidator` to the
/// `reactive.Validator` interface.
///
/// This wrapper converts the reactive [reactive.FormControl] into a [FormerControl]
/// and then calls the underlying validator.
///
/// Example:
/// ```dart
/// final reactiveControl = FormControl<String>(value: 'example');
/// final result = reactiveValidator.validate(reactiveControl);
/// ```
class _ReactiveWrappedValidator<T> implements reactive.Validator<T> {
  /// Creates a wrapper for the given `FormerControlValidator`.
  const _ReactiveWrappedValidator(this._validator);

  /// The underlying control validator being wrapped.
  final FormerControlValidator<T> _validator;

  /// Validates the given control by converting it to a [FormerControl] and
  /// invoking the wrapped validator.
  @override
  Map<String, dynamic>? validate(reactive.AbstractControl<T> control) {
    return _validator(
      FormerControl.fromReactive(control as reactive.FormControl<T>),
    );
  }

  /// Calls [validate] on the given control.
  @override
  Map<String, dynamic>? call(reactive.AbstractControl<T> control) {
    return validate(control);
  }
}
