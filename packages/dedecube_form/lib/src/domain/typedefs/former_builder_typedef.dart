import 'package:dedecube_form/src/domain/former_group.dart';
import 'package:flutter/widgets.dart';

/// A typedef for a builder function that constructs a widget based on the
/// current state of a [FormerGroup] form.
///
/// This function is typically used to build UI components that react to
/// changes in the form's state.
typedef FormerFormConsumerBuilder = Widget Function(
  BuildContext context,
  FormerGroup form,
  Widget? child,
);
