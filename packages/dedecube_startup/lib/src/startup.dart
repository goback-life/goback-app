import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/src/configs/startup_config.dart';
import 'package:dedecube_startup/src/contracts/startup_contract.dart';
import 'package:dedecube_startup/src/presentation/startup_container.dart';
import 'package:dedecube_startup/src/providers/initialize_complete_callback_provider.dart';
import 'package:dedecube_startup/src/providers/initialize_start_callback_provider.dart';
import 'package:dedecube_startup/src/providers/startup_config_provider.dart';
import 'package:dedecube_startup/src/providers/startup_provider.dart';
import 'package:flutter/material.dart';

class Startup implements StartupContract {
  Startup(this._config) {
    _init();
  }

  StartupConfig _config;

  @override
  StartupConfig get config => _config;

  @override
  set config(StartupConfig config) {
    _config = config;
    riverpodContainer()
        .read(startupConfigNotifierProvider.notifier)
        .startupConfig = _config;
  }

  void _init() {
    _registerDependencies();
    _configureStartupProvider();
  }

  void _registerDependencies() {
    final container = ProviderContainer();
    GetIt.I.registerSingleton<ProviderContainer>(container);
    GetIt.I.registerSingleton<StartupContract>(this);
  }

  void _configureStartupProvider() {
    riverpodContainer()
        .read(startupConfigNotifierProvider.notifier)
        .startupConfig = _config;
  }

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  static final _resolutionKey = GlobalKey();

  @override
  GlobalKey get resolutionKey => _resolutionKey;

  @override
  Startup initialize() {
    WidgetsFlutterBinding.ensureInitialized();
    _runApp();

    return this;
  }

  @override
  Startup onInitializeStart(InitializeStartCallback callback) {
    riverpodContainer().read(initializeStartCallbackProvider.notifier).state =
        callback;

    return this;
  }

  @override
  Startup onInitializeComplete(InitializeCompleteCallback callback) {
    riverpodContainer()
        .read(initializeCompleteCallbackProvider.notifier)
        .state = callback;

    return this;
  }

  void _runApp() {
    runApp(
      UncontrolledProviderScope(
        container: riverpodContainer(),
        child: StartupContainer(startupProvider: startupProvider(config)),
      ),
    );
  }
}

StartupContract get startup => GetIt.I.get<StartupContract>();
