import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/former_group.dart';

/// A typedef for a function that validates a `FormerControl`.
///
/// The function takes no parameters and returns a `Map<String, dynamic>?`
/// representing the validation result. If the validation passes, it can return
/// `null` or an empty map. If the validation fails, it should return a map
/// containing error information, where the keys are error codes and the values
/// provide additional details about the errors.
typedef FormerControlValidator<T> = Map<String, dynamic>? Function(
    FormerControl<T>);

/// A typedef for an asynchronous validator function for a `FormerControl`.
///
/// This function takes a `FormerControl` of type `T` as input and returns
/// a `Future` that resolves to a `Map<String, dynamic>?`. The returned map
/// represents validation errors, where the keys are error codes and the values
/// are error details. If the validation passes, the function should return `null`.
typedef FormerControlAsyncValidator<T> = Future<Map<String, dynamic>?> Function(
    FormerControl<T>);

/// A typedef for a function that validates a [FormerGroup].
///
/// The function takes a [FormerGroup] as input and returns a `Map<String, dynamic>?`.
/// The returned map typically contains validation results, where the keys represent
/// field names or validation identifiers, and the values represent validation messages
/// or other relevant data. If the validation passes without issues, the function may
/// return `null`.
typedef FormerGroupValidator = Map<String, dynamic>? Function(FormerGroup);

/// A typedef for an asynchronous group validator function used in form validation.
///
/// This function takes no parameters and returns a `Future` that resolves to a
/// `Map<String, dynamic>?`. The returned map typically contains validation errors
/// where the keys represent field names and the values describe the validation issues.
///
/// If the validation passes without errors, the function should return `null`.
typedef FormerAsyncGroupValidator = Future<Map<String, dynamic>?> Function(
    FormerGroup);
