import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A callable validator rule that checks if a value is present (non-null, non-empty).
class RequiredValidatorRule<T> {
  const RequiredValidatorRule();

  Map<String, dynamic>? call(FormerControl<T> control) {
    return reactive.Validators.required.validate(control.internal);
  }
}
