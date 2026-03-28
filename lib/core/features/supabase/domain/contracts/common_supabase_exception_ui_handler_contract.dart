import 'package:flutter/widgets.dart';

/// Contract for handling common Supabase exceptions in the UI layer.
/// Returns true if the exception was handled, false otherwise.
abstract class CommonSupabaseExceptionUIHandlerContract {
  bool handleSupabaseException({
    required BuildContext context,
    required Exception exception,
  });
}
