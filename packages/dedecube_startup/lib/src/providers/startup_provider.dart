import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_logger/dedecube_logger.dart';
import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_startup/src/configs/logger_config.dart';
import 'package:dedecube_startup/src/configs/router_config.dart';
import 'package:dedecube_startup/src/configs/startup_config.dart';
import 'package:dedecube_startup/src/configs/themify_config.dart';
import 'package:dedecube_startup/src/configs/translator_config.dart';
import 'package:dedecube_storage/dedecube_storage.dart';
import 'package:dedecube_themify/dedecube_themify.dart';
import 'package:dedecube_translator/dedecube_translator.dart';

final startupProvider = FutureProvider.family<void, StartupConfig>((
  ref,
  config,
) async {
  _unregisterDependencies();

  GetIt.I.registerSingleton<EnvironmentContract>(Environment());
  await environment.initialize();

  GetIt.I.registerSingleton<LoggerContract>(Logger(loggerConfig));

  GetIt.I.registerSingleton<TranslatorContract>(Translator(translatorConfig));

  GetIt.I.registerSingleton<RouterContract>(
    Router(
      routerConfig(config.routes, config.middlewares, (
        String action,
        BaseRoutable? route,
      ) {
        String? name = route?.name;
        for (final routable in config.routes) {
          if (routable.name == route?.name) {
            name = routable.path;
          }
        }

        logger.routerAction(action, name, route?.toMap);
      }),
    ),
  );

  GetIt.I.registerSingleton<ThemifyContract>(
    Themify(themifyConfig(config.supportedThemes, config.initialTheme)),
  );

  await Storage.initialize();
});

void _unregisterDependencies() {
  if (GetIt.I.isRegistered<EnvironmentContract>()) {
    GetIt.I.unregister<EnvironmentContract>();
  }
  if (GetIt.I.isRegistered<LoggerContract>()) {
    GetIt.I.unregister<LoggerContract>();
  }
  if (GetIt.I.isRegistered<TranslatorContract>()) {
    GetIt.I.unregister<TranslatorContract>();
  }
  if (GetIt.I.isRegistered<RouterContract>()) {
    GetIt.I.unregister<RouterContract>();
  }
  if (GetIt.I.isRegistered<ThemifyContract>()) {
    GetIt.I.unregister<ThemifyContract>();
  }
}
