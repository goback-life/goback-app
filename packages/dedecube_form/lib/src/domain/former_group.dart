import 'package:dedecube_form/src/data/reactive_async_group_validator_adapter.dart';
import 'package:dedecube_form/src/data/reactive_group_validator_adapter.dart';
import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_validator_typedef.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

class FormerGroup {
  /// Creates a [FormerGroup] from an existing [reactive.FormGroup].
  factory FormerGroup.fromReactive(reactive.FormGroup group) =>
      FormerGroup._(group);

  /// Creates a [FormerGroup] using a map of [FormerControl]s.
  ///
  /// Optionally accepts synchronous [validators] and asynchronous [asyncValidators]
  /// with a debounce time specified by [asyncValidatorsDebounceTime].
  factory FormerGroup(
    Map<String, FormerControl> controls, {
    List<FormerGroupValidator>? validators,
    List<FormerAsyncGroupValidator>? asyncValidators,
    int asyncValidatorsDebounceTime = 250,
  }) {
    final group = reactive.FormGroup(
      controls.map((key, control) => MapEntry(key, control.internal)),
      validators: validators?.map((v) => v.toReactive()).toList() ?? [],
      asyncValidators:
          asyncValidators?.map((v) => v.toReactive()).toList() ?? [],
      asyncValidatorsDebounceTime: asyncValidatorsDebounceTime,
    );

    return FormerGroup._(group);
  }

  const FormerGroup._(this._group);

  final reactive.FormGroup _group;

  /// The internal [reactive.FormGroup] instance.
  reactive.FormGroup get internal => _group;

  /// Returns true if the group is valid.
  bool get valid => _group.valid;

  /// Returns true if the group is invalid.
  bool get invalid => _group.invalid;

  /// Returns true if the group has been touched.
  bool get touched => _group.touched;

  /// Returns true if the group has been modified.
  bool get dirty => _group.dirty;

  /// Returns true if the group is disabled.
  bool get disabled => _group.disabled;

  /// Returns true if the group is enabled.
  bool get enabled => _group.enabled;

  /// Emits status changes of the group.
  Stream<reactive.ControlStatus> get statusChanges => _group.statusChanged;

  /// Emits value changes of the group.
  Stream<Map<String, dynamic>?> get valueChanges => _group.valueChanges;

  /// Returns the current group value.
  Map<String, dynamic> get value => _group.value;

  /// Access a control by its [name] and wrap it as a [FormerControl].
  ///
  /// The generic type [T] can be used to cast the control's value.
  FormerControl<T> control<T>(String name) {
    final ctrl = _group.control(name);
    return FormerControl.fromReactive(ctrl as reactive.FormControl<T>);
  }

  /// Enables the group.
  ///
  /// If [updateParent] is true, the parent's state is updated. If [emitEvent] is true,
  /// an event is fired to notify listeners.
  void enable({bool updateParent = true, bool emitEvent = true}) =>
      _group.markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Disables the group.
  ///
  /// If [updateParent] is true, the parent's state is updated. If [emitEvent] is true,
  /// an event is fired to notify listeners.
  void disable({bool updateParent = true, bool emitEvent = true}) =>
      _group.markAsDisabled(updateParent: updateParent, emitEvent: emitEvent);

  /// Marks all controls in the group as touched.
  void markAllAsTouched() => _group.markAllAsTouched();

  /// Marks all controls in the group as untouched.
  void markAllAsUntouched() => _group.markAsUntouched();

  /// Updates the group value.
  ///
  /// This method sets the provided [value] for the group.
  /// If [updateParent] is true, the parent group is also updated.
  /// If [emitEvent] is true, value change events are emitted.
  void updateValue(
    Map<String, dynamic> value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.updateValue(
        value,
        updateParent: updateParent,
        emitEvent: emitEvent,
      );

  /// Patches the group value.
  ///
  /// This method performs a partial update with the provided [value].
  /// If [updateParent] is true, the parent group is updated accordingly.
  /// If [emitEvent] is true, value change events are emitted.
  void patchValue(
    Map<String, dynamic> value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.patchValue(
        value,
        updateParent: updateParent,
        emitEvent: emitEvent,
      );

  /// Resets all values in the group.
  ///
  /// Optionally accepts a [value] map that sets the controls to a particular state
  /// after the reset.
  void reset({Map<String, dynamic>? value}) => _group.reset(value: value);

  /// Disposes all controls in the group.
  ///
  /// This method frees resources used by the group and its controls.
  void dispose() => _group.dispose();

  /// Removes focus from all controls in the group.
  void unfocus() => _group.unfocus();

  /// Sets focus to a specified control in the group.
  ///
  /// If [controlName] is provided, focus is set to that control.
  /// Otherwise, the default behavior is applied.
  void focus([String controlName = '']) => _group.focus(controlName);

  /// Returns true if the group contains a control with the given [name].
  bool contains(String name) => _group.contains(name);

  /// Returns the raw value of the group including disabled controls.
  Map<String, Object?> get rawValue => _group.rawValue;

  /// Returns all errors of the group.
  Map<String, Object> get errors => _group.errors;

  /// Adds all [controls] to the group.
  void addAll(Map<String, FormerControl> controls) => _group
      .addAll(controls.map((key, control) => MapEntry(key, control.internal)));

  /// Removes the control with the given [name] from the group.
  void removeControl(
    String name, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.removeControl(name,
          updateParent: updateParent, emitEvent: emitEvent);

  /// Recalculates the value and validation status of the group.
  void updateValueAndValidity({
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.updateValueAndValidity(
          updateParent: updateParent, emitEvent: emitEvent);

  /// Marks the group as dirty.
  void markAsDirty({
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.markAsDirty(updateParent: updateParent, emitEvent: emitEvent);

  /// Marks the group as pristine.
  void markAsPristine({
    bool updateParent = true,
  }) =>
      _group.markAsPristine(updateParent: updateParent);

  /// Marks the group as touched.
  void markAsTouched({
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      _group.markAsTouched(updateParent: updateParent, emitEvent: emitEvent);

  /// Executes [callback] for each child control in the group.
  void forEachChild(
          void Function(reactive.AbstractControl<dynamic>) callback) =>
      _group.forEachChild(callback);

  /// Returns true if any child control satisfies the given [condition].
  bool anyControls(
          bool Function(reactive.AbstractControl<dynamic>) condition) =>
      _group.anyControls(condition);

  /// Returns the map of child controls.
  Map<String, reactive.AbstractControl<dynamic>> get controls =>
      _group.controls;

  /// Resets the state of all controls in the group.
  void resetState(
    Map<String, reactive.ControlState<Object>> state, {
    bool removeFocus = false,
  }) =>
      _group.resetState(state, removeFocus: removeFocus);

  /// Returns true if any child control has the specified [status].
  bool anyControlsHaveStatus(reactive.ControlStatus status) =>
      _group.anyControlsHaveStatus(status);
}
