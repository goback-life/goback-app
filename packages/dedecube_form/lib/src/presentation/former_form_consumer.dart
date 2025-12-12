import 'package:dedecube_form/src/data/reactive_form_group_adapter.dart';
import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_builder_typedef.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A widget that listens to changes in the associated [FormerGroup] and rebuilds its child
/// using the provided [builder] callback.
///
/// This widget is a wrapper around the [reactive.ReactiveFormConsumer] and converts the underlying
/// [reactive.FormGroup] to a [FormerGroup] using the toFormer adapter.
///
/// The [builder] callback provides the current [FormerGroup] instance along with an optional [child],
/// which can be used to optimize rebuilds for portions of the widget tree that do not need to change.
class FormerFormConsumer extends StatelessWidget {
  /// Creates a [FormerFormConsumer].
  ///
  /// The [builder] parameter must not be null.
  const FormerFormConsumer({
    required this.builder,
    super.key,
    this.child,
  });

  /// The builder callback which is invoked whenever the form state changes.
  ///
  /// It provides a [FormerGroup] instance and an optional static [child] widget.
  final FormerFormConsumerBuilder builder;

  /// An optional widget that does not depend on the form state, which can be
  /// passed along for performance optimizations.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveFormConsumer(
      builder: (context, formGroup, child) {
        return builder(
          context,
          formGroup.toFormer,
          child,
        );
      },
      child: child,
    );
  }
}
