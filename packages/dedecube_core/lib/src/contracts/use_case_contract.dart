import 'dart:async';

/// An abstract interface class that defines a contract for use cases.
///
/// This class should be implemented by any use case class to ensure
/// a consistent interface for executing use cases and returning results.
///
/// Type Parameters:
/// - `Return`: The type of the result that the use case will return.
abstract interface class UseCaseContract<Return> {
  FutureOr<Return> execute();
}
