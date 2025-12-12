import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `FormerControlAsyncValidator` that provides a convenient method
/// to convert a `FormerControlAsyncValidator` into a `reactive.AsyncValidator`.
///
/// This extension adds the `toReactive` getter, which creates a
/// `reactive.AsyncValidator` instance from the current `FormerControlAsyncValidator`.
///
/// Example:
/// ```dart
/// final asyncValidator = (FormerControl<String> control) async {
///   // Your async validation logic...
///   return null;
/// };
///
/// final reactiveValidator = asyncValidator.toReactive;
/// ```
extension ReactiveAsyncValidatorAdapter<T> on FormerControlAsyncValidator<T> {
  reactive.AsyncValidator<T> toReactive() =>
      _ReactiveWrappedAsyncValidator<T>(this);
}

/// A wrapper that adapts a `FormerControlAsyncValidator` to the
/// `reactive.AsyncValidator` interface.
///
/// This wrapper converts the reactive [reactive.FormControl] into a [FormerControl]
/// and then calls the underlying async validator.
///
/// Example:
/// ```dart
/// final reactiveControl = FormControl<String>(value: 'example');
/// final formerControl = FormerControl.fromReactive(reactiveControl);
/// // Use the reactive async validator:
/// final result = await reactiveValidator.validate(reactiveControl);
/// ```
class _ReactiveWrappedAsyncValidator<T> implements reactive.AsyncValidator<T> {
  /// Creates a wrapper for the given `FormerControlAsyncValidator`.
  const _ReactiveWrappedAsyncValidator(this._validator);

  /// The underlying async validator being wrapped.
  final FormerControlAsyncValidator<T> _validator;

  /// Validates the given control by converting it to a [FormerControl]
  /// and invoking the wrapped async validator.
  @override
  Future<Map<String, dynamic>?> validate(reactive.AbstractControl<T> control) {
    return _validator(
      FormerControl.fromReactive(control as reactive.FormControl<T>),
    );
  }

  /// Calls [validate] on the given control.
  @override
  Future<Map<String, dynamic>?> call(reactive.AbstractControl<T> control) {
    return validate(control);
  }
}
