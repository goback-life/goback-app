import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A widget that binds to a [FormerControl] and rebuilds when its value changes.
///
/// This is a wrapper around [reactive.ReactiveValueListenableBuilder].
class FormerFormValueListenable<T> extends StatelessWidget {
  const FormerFormValueListenable({
    required this.control,
    required this.builder,
    super.key,
    this.child,
  });

  /// The [FormerControl] to listen to.
  final FormerControl<T> control;

  /// The builder that creates a widget depending on the value of the control.
  final Widget Function(
      BuildContext context, FormerControl<T> control, Widget? child) builder;

  /// An optional child widget that does not depend on the control's value.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveValueListenableBuilder<T>(
      formControl: control.internal,
      builder: (context, formControl, child) =>
          builder(context, control, child),
      child: child,
    );
  }
}
