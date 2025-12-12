import 'package:dedecube_startup/src/startup.dart';
import 'package:flutter/widgets.dart';

/// Returns the global resolution key used for managing resolution states in the startup application.
///
/// This getter provides access to the [GlobalKey], which is typically used for
/// handling resolution-specific UI states such as error handling, retries, or
/// custom actions during app initialization.
GlobalKey get startupResolutionKey => startup.resolutionKey;
