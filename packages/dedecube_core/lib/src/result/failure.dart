part of 'result.dart';

/// A class representing a failure result in an operation.
///
/// This class extends the [Result] class and encapsulates an error
/// of type [Exception]. It provides methods to handle the failure
/// case using functional programming concepts.
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final Exception error;

  @override
  U fold<U>(
    U Function(T value) onSuccess,
    U Function(Exception error) onFailure,
  ) =>
      onFailure(error);

  @override
  Future<U> asyncFold<U>(
    Future<U> Function(T value) onSuccess,
    Future<U> Function(Exception error) onFailure,
  ) async {
    return onFailure(error);
  }
}
