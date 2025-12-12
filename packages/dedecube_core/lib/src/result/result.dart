part 'failure.dart';
part 'success.dart';

/// A sealed class that represents the result of an operation, which can hold
/// a value of type `T`. This class is intended to be extended to define
/// specific result types, such as success or failure, providing a structured
/// way to handle outcomes in a type-safe manner.
sealed class Result<T> {
  const Result();

  factory Result.success(T value) => Success(value);
  factory Result.failure(Exception error) => Failure(error);

  U fold<U>(
    U Function(T value) onSuccess,
    U Function(Exception error) onFailure,
  );

  Future<U> asyncFold<U>(
    Future<U> Function(T value) onSuccess,
    Future<U> Function(Exception error) onFailure,
  );
}

typedef FutureResult<T> = Future<Result<T>>;
