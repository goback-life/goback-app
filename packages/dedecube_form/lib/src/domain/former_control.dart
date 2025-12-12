import 'dart:async';

import 'package:dedecube_form/src/data/reactive_async_validator_adapter.dart';
import 'package:dedecube_form/src/data/reactive_validator_adapter.dart';
import 'package:dedecube_form/src/domain/former_abstract_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A wrapper for [reactive.FormControl] that provides a domain-specific,
/// type-safe API.
class FormerControl<T> {
  /// Creates a [FormerControl] with an optional initial [value],
  /// synchronous [validators], asynchronous [asyncValidators],
  /// and initial [touched] or [disabled] states.
  ///
  /// To debounce async validators, use [reactive.Validators.debounced] per validator.
  factory FormerControl({
    T? value,
    List<FormerControlValidator<T>>? validators,
    List<FormerControlAsyncValidator<T>>? asyncValidators,
    bool touched = false,
    bool disabled = false,
  }) {
    return FormerControl._(
      reactive.FormControl<T>(
        value: value,
        validators: validators?.map((v) => v.toReactive()).toList() ?? [],
        asyncValidators:
            asyncValidators?.map((v) => v.toReactive()).toList() ?? [],
        touched: touched,
        disabled: disabled,
      ),
    );
  }

  /// Internal constructor for [FormerControl].
  const FormerControl._(this._control);

  /// Creates a [FormerControl] from an existing [reactive.FormControl].
  factory FormerControl.fromReactive(reactive.FormControl<T> control) {
    return FormerControl._(control);
  }

  /// The underlying reactive form control.
  final reactive.FormControl<T> _control;

  /// Gets the current value of the control.
  T? get value => _control.value;

  /// Sets a new value for the control.
  set value(T? newValue) => _control.value = newValue;

  /// A stream that emits the current value whenever it changes.
  Stream<T?> get valueChanges => _control.valueChanges;

  /// A stream that emits the current status whenever it changes.
  Stream<reactive.ControlStatus> get statusChanges => _control.statusChanged;

  /// Returns true if the control is currently valid.
  bool get valid => _control.valid;

  /// Returns true if the control is currently invalid.
  bool get invalid => _control.invalid;

  /// Returns true if the control has been touched.
  bool get touched => _control.touched;

  /// Returns true if the control's value has been changed (i.e. is dirty).
  bool get dirty => _control.dirty;

  /// Returns true if the control is disabled.
  bool get disabled => _control.disabled;

  /// Returns true if the control currently has focus.
  bool get hasFocus => _control.hasFocus;

  /// Returns true if the control is enabled.
  bool get enabled => _control.enabled;

  /// Checks if the control has an error with the specified [errorCode].
  ///
  /// If an optional [path] is provided, error checking will be performed at that path.
  bool hasError(String errorCode, [String? path]) {
    return _control.hasError(errorCode, path);
  }

  /// Retrieves the error value for the given [errorCode],
  /// or null if the error does not exist.
  dynamic getError(String errorCode, [String? path]) {
    return _control.getError(errorCode, path);
  }

  /// Sets focus on this control.
  void focus() => _control.focus();

  /// Removes focus from this control.
  ///
  /// If [touched] is true, the control will be marked as touched.
  void unfocus({bool touched = true}) => _control.unfocus(touched: touched);

  /// Marks the control as touched.
  ///
  /// When [updateParent] is true, the parent control is also updated.
  void markAsTouched({bool updateParent = true}) =>
      _control.markAsTouched(updateParent: updateParent);

  /// Marks the control as untouched.
  ///
  /// When [updateParent] is true, the parent control is also updated.
  void markAsUntouched({bool updateParent = true}) =>
      _control.markAsUntouched(updateParent: updateParent);

  /// Enables the control.
  ///
  /// Optional parameters [updateParent] and [emitEvent] control
  /// whether the parent control is updated and whether events are emitted.
  void enable({bool updateParent = true, bool emitEvent = true}) =>
      _control.markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Disables the control.
  ///
  /// Optional parameters [updateParent] and [emitEvent] control
  /// whether the parent control is updated and whether events are emitted.
  void disable({bool updateParent = true, bool emitEvent = true}) =>
      _control.markAsDisabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Updates the value of the control.
  ///
  /// [updateParent] indicates if the parent control should also update.
  /// [emitEvent] indicates if the change event should be emitted.
  void updateValue(
    T? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _control.updateValue(
        value,
        updateParent: updateParent,
        emitEvent: emitEvent,
      );

  /// Patches the value of the control.
  ///
  /// [updateParent] indicates if the parent control should also update.
  /// [emitEvent] indicates if the change event should be emitted.
  void patchValue(
    T? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _control.patchValue(
        value,
        updateParent: updateParent,
        emitEvent: emitEvent,
      );

  /// Updates the validity status of the control.
  ///
  /// If [updateParent] is true and the control has a parent, the parent is updated.
  /// If [emitEvent] is true, relevant events are emitted to subscribers.
  void updateValueAndValidity({
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _control.updateValueAndValidity(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );

  /// Disposes the control, releasing any allocated resources.
  void dispose() => _control.dispose();

  /// Sets errors on the control.
  ///
  /// If [markAsDirty] is true, the control is marked as dirty.
  void setErrors(Map<String, dynamic> errors, {bool markAsDirty = true}) {
    _control.setErrors(errors, markAsDirty: markAsDirty);
  }

  /// Sets errors on the control and marks it as touched.
  ///
  /// This is an alternative to [setErrors] that calls [markAsTouched]
  /// after setting errors.
  void setErrorsAndTouch(Map<String, dynamic> errors,
      {bool markAsDirty = true}) {
    _control.setErrors(errors, markAsDirty: markAsDirty);
    markAsTouched();
  }

  /// Retrieves current errors from the control.
  Map<String, dynamic>? get errors => _control.errors;

  /// Provides access to the underlying [reactive.FormControl].
  ///
  /// External use is discouraged.
  reactive.FormControl<T> get internal => _control;

  /// Registers a [reactive.FocusController] with the control.
  void registerFocusController(reactive.FocusController focusController) =>
      _control.registerFocusController(focusController);

  /// Unregisters the specified [reactive.FocusController] from the control.
  void unregisterFocusController(reactive.FocusController focusController) =>
      _control.unregisterFocusController(focusController);

  /// A stream that emits changes to the control's focus state.
  Stream<bool> get focusChanges => _control.focusChanges;

  /// Returns true if the control is pristine (has not been modified).
  bool get pristine => _control.pristine;

  /// Returns the current validation status of the control.
  reactive.ControlStatus get status => _control.status;

  /// Gets the [reactive.FocusController] associated with the control, if any.
  reactive.FocusController? get focusController => _control.focusController;

  /// Resets the control.
  ///
  /// [value] is the new value to set.
  /// [updateParent] specifies whether the parent should also update.
  /// [emitEvent] specifies whether events should be fired.
  /// [removeFocus] indicates if UI focus should be removed.
  /// [disabled] can be used to set the control's disabled state during reset.
  void reset({
    T? value,
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) {
    _control.reset(
      value: value,
      updateParent: updateParent,
      emitEvent: emitEvent,
      removeFocus: removeFocus,
      disabled: disabled,
    );
  }

  /// Converts a [FormerControl] to a [FormerAbstractControl].
  FormerAbstractControl<T> toAbstract() => FormerAbstractControl<T>(internal);
}
