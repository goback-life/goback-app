import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:dedecube_form/src/domain/typedefs/former_navigation_callbacks_typedef.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

class FormerForm extends StatelessWidget {
  const FormerForm({
    required this.form,
    required this.child,
    super.key,
    this.canPop,
    this.onPopInvoked,
  });

  /// The former group control that is bound to this widget.
  final FormerGroup form;

  /// The widget subtree that represents the content of the form.
  ///
  /// Typically, this includes all input fields, buttons, and any UI
  /// elements that interact with the [FormerGroup].
  final Widget child;

  /// Determine whether a route can popped. See [PopScope] for more details.
  final FormerFormCanPopCallback? canPop;

  /// A callback invoked when a route is popped. See [PopScope] for more details.
  final FormerFormPopInvokedCallback? onPopInvoked;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveForm(
      formGroup: form.internal,
      canPop: canPop != null
          ? (group) => canPop!(FormerGroup.fromReactive(group))
          : null,
      child: child,
    );
  }
}
