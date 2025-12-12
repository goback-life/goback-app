import 'dart:core';

import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `FormerGroupValidator` that provides a convenient method
/// to convert a `FormerGroupValidator` into a `reactive.Validator<Map<String, dynamic>>`.
///
/// This extension adds the `toReactive` getter, which wraps the current
/// `FormerGroupValidator` instance into a reactive validator,
/// allowing it to be used seamlessly within the reactive forms framework.
///
/// Example:
/// ```dart
/// final groupValidator = (FormerGroup group) {
///   // Your validation logic...
///   return null;
/// };
///
/// final reactiveValidator = groupValidator.toReactive;
/// ```
extension ReactiveGroupValidatorAdapter on FormerGroupValidator {
  reactive.Validator<Map<String, dynamic>> toReactive() =>
      _ReactiveWrappedGroupValidator(this);
}

/// A wrapper that adapts a `FormerGroupValidator` to the
/// `reactive.Validator<Map<String, dynamic>>` interface.
///
/// This wrapper converts the reactive [reactive.FormGroup] into a [FormerGroup]
/// and then calls the underlying validator.
///
/// Example:
/// ```dart
/// final reactiveControl = FormGroup({...});
/// final result = reactiveValidator.validate(reactiveControl);
/// ```
class _ReactiveWrappedGroupValidator
    implements reactive.Validator<Map<String, dynamic>> {
  /// Creates a wrapper for the given `FormerGroupValidator`.
  const _ReactiveWrappedGroupValidator(this._validator);

  /// The underlying group validator being wrapped.
  final FormerGroupValidator _validator;

  /// Validates the given control by converting it to a [FormerGroup] and invoking
  /// the wrapped group validator.
  @override
  Map<String, dynamic>? validate(
      reactive.AbstractControl<Map<String, dynamic>> control) {
    return _validator(FormerGroup.fromReactive(control as reactive.FormGroup));
  }

  /// Calls [validate] on the given control.
  @override
  Map<String, dynamic>? call(
      reactive.AbstractControl<Map<String, dynamic>> control) {
    return validate(control);
  }
}
