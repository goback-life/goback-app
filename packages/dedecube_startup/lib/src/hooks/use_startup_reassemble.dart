import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_logger/dedecube_logger.dart';
import 'package:dedecube_startup/src/configs/logger_config.dart';
import 'package:dedecube_startup/src/configs/translator_config.dart';
import 'package:dedecube_startup/src/providers/environment_initialized_provider.dart';
import 'package:dedecube_startup/src/utilities/translator_versioning.dart';
import 'package:dedecube_translator/dedecube_translator.dart';
import 'package:flutter/material.dart';

void useStartupReassemble(WidgetRef ref) {
  final environmentInitializedNotifier = ref.read(
    environmentInitializedNotifierProvider.notifier,
  );

  useReassemble(() {
    // Indicate that we are reloading the env.
    environmentInitializedNotifier.isInitialized = false;
    ref.invalidate(environmentServiceProvider);

    environment.initialize().then((_) {
      // Reloading completed.
      environmentInitializedNotifier.isInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        logger.config = loggerConfig;
        translator.config = translatorConfig;
        TranslatorVersioning.updateTranslations();
      });
    });
  });
}
