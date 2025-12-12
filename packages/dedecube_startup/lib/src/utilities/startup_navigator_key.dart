import 'package:dedecube_startup/src/startup.dart';
import 'package:flutter/widgets.dart';

/// Returns the global navigator key used for navigation within the startup application.
///
/// This getter provides access to the [GlobalKey] of type [NavigatorState],
/// which is associated with the main navigator of the application. It enables
/// navigation operations from anywhere in the app without requiring a [BuildContext].
GlobalKey<NavigatorState> get startupNavigatorKey => startup.navigatorKey;
