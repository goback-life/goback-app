import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `FormControl` from the `reactive_forms` package that provides
/// a convenient method to convert a `FormControl` into a `FormerControl`.
///
/// This extension adds the `toFormer` getter, which creates a `FormerControl`
/// instance from the current `FormControl`.
///
/// Example:
/// ```dart
/// final reactiveControl = FormControl<String>(value: 'example');
/// final formerControl = reactiveControl.toFormer;
/// ```
extension ReactiveFormAdapter<T> on reactive.FormControl<T> {
  FormerControl<T> get toFormer => FormerControl.fromReactive(this);
}
