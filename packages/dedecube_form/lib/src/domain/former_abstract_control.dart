import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A wrapper for [reactive.AbstractControl] that allows you to use it in your own API.
class FormerAbstractControl<T> {
  /// Creates a [FormerAbstractControl] from a [reactive.AbstractControl].
  const FormerAbstractControl(this.control);

  /// The underlying [reactive.AbstractControl].
  final reactive.AbstractControl<T> control;

  /// Returns the current value of the control.
  T? get value => control.value;

  /// Returns the current status of the control.
  reactive.ControlStatus get status => control.status;

  /// Returns true if the control is valid.
  bool get valid => control.valid;

  /// Returns true if the control is invalid.
  bool get invalid => control.invalid;

  /// Returns true if the control is touched.
  bool get touched => control.touched;

  /// Returns true if the control is dirty.
  bool get dirty => control.dirty;

  /// Returns true if the control is disabled.
  bool get disabled => control.disabled;

  /// Returns true if the control is enabled.
  bool get enabled => control.enabled;

  /// Returns a stream of value changes.
  Stream<T?> get valueChanges => control.valueChanges;

  /// Returns a stream of status changes.
  Stream<reactive.ControlStatus> get statusChanges => control.statusChanged;

  /// Calls the underlying control's [markAsTouched] method.
  void markAsTouched({bool updateParent = true}) =>
      control.markAsTouched(updateParent: updateParent);

  /// Calls the underlying control's [markAsUntouched] method.
  void markAsUntouched({bool updateParent = true}) =>
      control.markAsUntouched(updateParent: updateParent);

  /// Calls the underlying control's [markAsDirty] method.
  void markAsDirty({bool updateParent = true, bool emitEvent = true}) =>
      control.markAsDirty(updateParent: updateParent, emitEvent: emitEvent);

  /// Calls the underlying control's [markAsPristine] method.
  void markAsPristine({bool updateParent = true}) =>
      control.markAsPristine(updateParent: updateParent);

  /// Calls the underlying control's [enable] method.
  void enable({bool updateParent = true, bool emitEvent = true}) =>
      control.markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Calls the underlying control's [disable] method.
  void disable({bool updateParent = true, bool emitEvent = true}) =>
      control.markAsDisabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Calls the underlying control's [dispose] method.
  void dispose() => control.dispose();

  /// Returns the underlying [reactive.AbstractControl] instance.
  reactive.AbstractControl<T> asReactive() => control;

  /// Returns this control as a [FormerGroup] if it is a group, otherwise null.
  FormerGroup? get group {
    final group = control.parent is reactive.FormGroup
        ? control.parent! as reactive.FormGroup
        : null;
    return group != null ? FormerGroup.fromReactive(group) : null;
  }
}
