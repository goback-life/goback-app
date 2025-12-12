import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `FormerAsyncGroupValidator` that provides a convenient method
/// to convert a `FormerAsyncGroupValidator` into a `reactive.AsyncValidator<Map<String, dynamic>>`.
///
/// This extension adds the `toReactive` getter, which wraps the current
/// `FormerAsyncGroupValidator` instance into a reactive async validator,
/// allowing it to be used seamlessly within the reactive forms framework.
///
/// Example:
/// ```dart
/// final asyncGroupValidator = (FormerGroup group) async {
///   // Your async validation logic...
///   return null;
/// };
///
/// final reactiveValidator = asyncGroupValidator.toReactive;
/// ```
extension ReactiveAsyncGroupValidatorAdapter on FormerAsyncGroupValidator {
  reactive.AsyncValidator<Map<String, dynamic>> toReactive() =>
      _ReactiveWrappedAsyncGroupValidator(this);
}

/// A wrapper that adapts a `FormerAsyncGroupValidator` to the
/// `reactive.AsyncValidator<Map<String, dynamic>>` interface.
///
/// This wrapper converts the reactive [reactive.FormGroup] to a [FormerGroup] and then
/// invokes the underlying async group validator.
class _ReactiveWrappedAsyncGroupValidator
    implements reactive.AsyncValidator<Map<String, dynamic>> {
  /// Creates a wrapper for the given `FormerAsyncGroupValidator`.
  const _ReactiveWrappedAsyncGroupValidator(this._validator);

  /// The underlying async group validator being wrapped.
  final FormerAsyncGroupValidator _validator;

  /// Validates the given control by converting it to a `FormerGroup` and calling
  /// the underlying validator.
  @override
  Future<Map<String, dynamic>?> validate(
      reactive.AbstractControl<Map<String, dynamic>> control) {
    return _validator(
      FormerGroup.fromReactive(control as reactive.FormGroup),
    );
  }

  /// Calls the [validate] method on the given control.
  @override
  Future<Map<String, dynamic>?> call(
      reactive.AbstractControl<Map<String, dynamic>> control) {
    return validate(control);
  }
}
