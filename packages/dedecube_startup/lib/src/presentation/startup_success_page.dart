import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/src/hooks/use_router_config.dart';
import 'package:dedecube_startup/src/presentation/startup_loading_page.dart';
import 'package:dedecube_startup/src/providers/environment_initialized_provider.dart';
import 'package:dedecube_startup/src/providers/locale_provider.dart';
import 'package:dedecube_startup/src/providers/startup_config_provider.dart';
import 'package:dedecube_startup/src/providers/theme_provider.dart';
import 'package:dedecube_startup/src/utilities/startup_resolution_key.dart';
import 'package:dedecube_startup/src/utilities/translator_versioning.dart';
import 'package:dedecube_themify/dedecube_themify.dart';
import 'package:dedecube_translator/dedecube_translator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;

/// A widget that represents a successful startup page.
///
/// This widget wraps a [material.MaterialApp] with localization support and custom theme settings.
/// It uses [material.StreamBuilder] to handle locale changes and applies them in real-time.
///
/// This widget is used as the root widget after the application has
/// successfully initialized all required resources and dependencies.
class StartupSuccessPage extends HookConsumerWidget {
  const StartupSuccessPage({super.key});

  @override
  material.Widget build(material.BuildContext context, WidgetRef ref) {
    final routerConfig = useRouterConfig();

    if (kDebugMode) {
      return material.StreamBuilder<int>(
        initialData: TranslatorVersioning.version,
        stream: TranslatorVersioning.versionStream,
        builder: (context, versionSnapshot) {
          final version = versionSnapshot.data;
          return _buildMaterialApp(version, routerConfig, ref);
        },
      );
    }

    return _buildMaterialApp(0, routerConfig, ref);
  }

  material.Widget _buildMaterialApp(
    int? version,
    material.RouterConfig<Object>? routerConfig,
    WidgetRef ref,
  ) {
    final themeAsync = ref.watch(themeProvider);
    final localeAsync = ref.watch(localeProvider);
    final startupConfig = ref.watch(startupConfigNotifierProvider);

    final theme = themeAsync.when(
      data: (theme) => theme,
      loading: () => themify.currentTheme,
      error: (_, __) => themify.currentTheme,
    );

    final locale = localeAsync.when(
      data: (locale) => locale,
      loading: () => translator.currentLocale,
      error: (_, __) => translator.currentLocale,
    );

    // Combine translator's localization delegates with custom ones
    final List<material.LocalizationsDelegate> combinedDelegates = [
      ...translator.localizationsDelegates,
      if (startupConfig.localizationsDelegates != null)
        ...startupConfig.localizationsDelegates!,
    ];

    final materialApp = material.MaterialApp.router(
      key: ValueKey(version),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: combinedDelegates,
      supportedLocales: translator.supportedLocales,
      locale: locale,
      theme: theme?.configuredThemeData,
      builder: (context, child) {
        final container = material.Container(
          color: theme?.configuredThemeData.scaffoldBackgroundColor ??
              material.Colors.white,
          child: _builder(context, child, ref),
        );

        // If appBuilder is provided, wrap the container with it
        if (startupConfig.appBuilder != null) {
          return startupConfig.appBuilder!(context, container);
        }

        return container;
      },
      routerConfig: routerConfig,
    );

    return materialApp;
  }

  material.Widget _builder(
    material.BuildContext context,
    material.Widget? child,
    WidgetRef ref,
  ) {
    return material.Builder(
      key: startupResolutionKey,
      builder: (context) {
        final environmentReady = ref.watch(
          environmentInitializedNotifierProvider,
        );
        if (!environmentReady) {
          return const StartupLoadingPage();
        } else {
          return child!;
        }
      },
    );
  }
}
