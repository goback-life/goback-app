import 'package:dedecube_startup/src/startup.dart';
import 'package:flutter/material.dart';

/// Returns the current [BuildContext] of the application.
///
/// This getter provides access to the global navigation context by utilizing
/// the navigatorKey from the startup contract. It allows you to perform
/// navigation or access context-specific features without requiring
/// a [BuildContext] directly in your widget.
BuildContext get startupContext => startup.navigatorKey.currentContext!;
