part of 'result.dart';

/// A class representing a successful result of an operation.
///
/// This class extends the [Result] class and is used to encapsulate
/// a value of type [T] that signifies a successful outcome.
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  U fold<U>(
    U Function(T value) onSuccess,
    U Function(Exception error) onFailure,
  ) =>
      onSuccess(value);

  @override
  Future<U> asyncFold<U>(
    Future<U> Function(T value) onSuccess,
    Future<U> Function(Exception error) onFailure,
  ) async {
    return onSuccess(value);
  }
}
