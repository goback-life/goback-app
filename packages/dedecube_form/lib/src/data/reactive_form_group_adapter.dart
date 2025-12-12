import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// An extension on `reactive.FormGroup` that provides a method to convert
/// a `reactive.FormGroup` instance into a `FormerGroup` instance.
///
/// This extension adds the `toFormer` getter, which utilizes the
/// `FormerGroup.fromReactive` factory constructor to perform the conversion.
extension ReactiveFormGroupAdapter on reactive.FormGroup {
  FormerGroup get toFormer => FormerGroup.fromReactive(this);
}
