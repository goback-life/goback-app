import 'package:dedecube_core/dedecube_core.dart';

abstract class SupabaseResultProcessorContract {
  /// Executes a Supabase request and maps its result with unified exception handling.
  ///
  /// [request] executes the Supabase call and returns a [Future<Result<R>>].
  /// [responseMapper] transforms a successful response of type [R] into the target type [T].
  /// [exceptionMapper] converts a [Exception] into a domain [Exception].
  /// [onBefore] is an optional callback executed before the request.
  /// [onAfter] is an optional callback executed after the request completes.
  FutureResult<T> processSupabaseResult<R, T>({
    required Future<Result<R>> Function() request,
    required Future<T> Function(R) responseMapper,
    required Exception Function(Exception) exceptionMapper,
    void Function()? onBefore,
    void Function()? onAfter,
  });
}
