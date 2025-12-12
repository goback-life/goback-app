import 'package:flutter/widgets.dart';

/// A contract for handling Supabase result UI interactions.
///
/// This abstract class defines a method that must be implemented to handle
/// the user interface response to Supabase results, such as displaying error
/// messages or handling exceptions.
///
/// Implementations of this contract should provide specific logic for
/// managing the UI behavior when a Supabase exception occurs.
abstract class CommonSupabaseExceptionUIHandlerContract {
  /// Handles the user interface response to a Supabase result.
  ///
  /// This method is responsible for processing the given [exception] and
  /// updating the UI accordingly within the provided [context].
  ///
  /// Returns `true` if the exception was successfully handled and the UI
  /// was updated, or `false` if no action was taken.
  ///
  /// - [context]: The [BuildContext] used to interact with the Flutter widget tree.
  /// - [exception]: The [Exception] that occurred during a Supabase request.
  bool handleSupabaseException({
    required BuildContext context,
    required Exception exception,
  });
}
