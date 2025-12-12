import 'package:flutter/material.dart';

/// Extension on [PageController] that provides safe access to page-related properties.
///
/// This extension helps prevent common null pointer exceptions and edge cases
/// when accessing [PageController] properties before the controller is properly initialized.
extension PageControllerSafe on PageController {
  /// Whether the [PageController] is safe to access page-related properties.
  ///
  /// Returns `true` if the controller has clients and the position has content dimensions.
  bool get isSafe => hasClients && position.hasContentDimensions;

  /// Safely retrieves the current page value.
  ///
  /// Returns the current page if the controller is safe to access,
  /// otherwise returns the [initialPage] value as a double.
  double get safePage {
    if (isSafe) {
      if (page case final double page) {
        return page;
      }
    }
    return initialPage.toDouble();
  }
}
