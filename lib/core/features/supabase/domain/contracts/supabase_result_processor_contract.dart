import 'package:dedecube_core/dedecube_core.dart';

/// Contract for unified Supabase request execution with error handling.
abstract class SupabaseResultProcessorContract {
  FutureResult<T> processSupabaseResult<R, T>({
    required Future<Result<R>> Function() request,
    required Future<T> Function(R) responseMapper,
    required Exception Function(Exception) exceptionMapper,
    void Function()? onBefore,
    void Function()? onAfter,
  });
}
