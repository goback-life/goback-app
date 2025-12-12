import 'package:dedecube_startup/src/configs/startup_config.dart';
import 'package:dedecube_startup/src/providers/initialize_complete_callback_provider.dart';
import 'package:dedecube_startup/src/providers/initialize_start_callback_provider.dart';
import 'package:dedecube_startup/src/startup.dart';
import 'package:flutter/material.dart';

abstract class StartupContract {
  /// Retrieves the current startup configuration.
  ///
  /// This getter provides access to the current [StartupConfig], which includes parameters such as:
  /// - A list of defined routes ([StartupConfig.routes]).
  /// - Custom widgets for loading ([StartupConfig.loadingPage]).
  /// - Custom widgets for error handling ([StartupConfig.errorPage]).
  StartupConfig get config;

  /// Sets the startup configuration for the application.
  ///
  /// This setter updates the [StartupConfig] used by the application, replacing
  /// the existing configuration. It allows you to customize:
  /// - Application routes.
  /// - Loading and error widgets.
  set config(StartupConfig config);

  /// Initializes the startup process.
  ///
  /// This method is responsible for setting up the necessary configurations
  /// and resources required to start the application.
  Startup initialize();

  /// Registers a callback to be executed when the startup initialization starts.
  Startup onInitializeStart(InitializeStartCallback callback);

  /// Registers a callback to be invoked when the initialization is complete.
  Startup onInitializeComplete(InitializeCompleteCallback callback);

  /// Provides access to the global [NavigatorState] of the application.
  ///
  /// The [navigatorKey] allows navigation actions to be performed anywhere in
  /// the app without needing a [BuildContext].
  GlobalKey<NavigatorState> get navigatorKey;

  /// A global key used for managing resolution states, such as error handling or retries.
  ///
  /// Use the [resolutionKey] to manage widget states involved in handling
  /// initialization issues, such as showing retry buttons or error messages.
  GlobalKey get resolutionKey;
}
