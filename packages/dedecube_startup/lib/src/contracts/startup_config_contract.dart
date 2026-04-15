import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_themify/dedecube_themify.dart';
import 'package:flutter/material.dart';

abstract class StartupConfigContract {
  /// A list of route contracts that define the available routes in the application.
  ///
  /// Each [BaseRoutable] specifies parameters such as:
  /// - The route's name (e.g., '/home', '/settings').
  /// - The widget (screen) associated with the route.
  List<BaseRoutable> get routes;

  /// A list of middleware contracts that define the middleware for the application.
  ///
  /// Each [Middleware] specifies parameters such as:
  /// - The middleware's name (e.g., 'auth', 'logging').
  /// - The function that will be executed when the middleware is triggered.
  List<Middleware> get middlewares;

  /// A list of themes supported by the application.
  ///
  /// Each [Themable] specifies parameters such as:
  /// - The theme's name.
  /// - The theme's data (e.g., colors, typography).
  List<Themable>? get supportedThemes;

  Themable? get initialTheme;

  /// The widget displayed while the application is loading resources or initializing.
  ///
  /// **Important:** This widget must return a [MaterialApp] at its root.
  ///
  /// If not set, a default loading widget will be used.
  Widget? loadingPage;

  /// The widget displayed when an error occurs during app initialization.
  ///
  /// **Important:** This widget must return a [MaterialApp] at its root to ensure proper
  /// navigation and theme management.
  ///
  /// If not set, a default error widget will be used.
  Widget? errorPage;

  /// A builder function to wrap the MaterialApp content with custom widgets.
  ///
  /// This function is called within the MaterialApp's builder, allowing you to
  /// wrap the app content with widgets that need access to the MaterialApp's
  /// context (with localization, theme, etc.) while still being at a high level.
  ///
  /// The `context` parameter has access to MaterialApp's localization delegates,
  /// theme, and other inherited widgets.
  ///
  /// Example:
  /// ```dart
  /// appBuilder: (context, child) => StreamChat(
  ///   client: streamChatClient,
  ///   child: child,
  /// )
  /// ```
  Widget Function(BuildContext context, Widget child)? get appBuilder;

  /// Additional localization delegates to be added to the MaterialApp.
  ///
  /// These delegates will be combined with the default translator localization
  /// delegates, allowing you to add custom localization support for third-party
  /// packages or custom localizations.
  ///
  /// Example:
  /// ```dart
  /// localizationsDelegates: [
  ///   GlobalMaterialLocalizations.delegate,
  ///   GlobalWidgetsLocalizations.delegate,
  ///   MyCustomLocalizations.delegate,
  /// ]
  /// ```
  List<LocalizationsDelegate>? get localizationsDelegates;

  /// The filename of the environment file to load (e.g., '.env.stage').
  ///
  /// If not set, defaults to '.env'.
  String? get envFilename;
}
