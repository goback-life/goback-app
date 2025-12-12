import 'package:dedecube_form/src/domain/former_group.dart';

/// A typedef for a callback function that determines whether a
/// [FormerGroup] can be popped (navigated away from).
///
/// This function should return a boolean value:
/// - `true` if the [FormerGroup] can be popped.
/// - `false` if the [FormerGroup] cannot be popped.
///
/// Useful for implementing custom navigation logic in forms.
typedef FormerFormCanPopCallback = bool Function(FormerGroup);

/// A callback type definition that is invoked when a form pop action occurs.
///
/// This callback is triggered when a form is popped from the navigation stack.
/// It can be used to perform cleanup, analytics, or intercept navigation behavior.
typedef FormerFormPopInvokedCallback = void Function(
  FormerGroup form,
  // ignore: avoid_positional_boolean_parameters
  bool didPop,
);
