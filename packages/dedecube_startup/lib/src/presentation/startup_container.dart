import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/src/hooks/use_initialize_complete_callback.dart';
import 'package:dedecube_startup/src/hooks/use_startup_initialization.dart';
import 'package:dedecube_startup/src/hooks/use_startup_reassemble.dart';
import 'package:dedecube_startup/src/presentation/startup_error_page.dart';
import 'package:dedecube_startup/src/presentation/startup_loading_page.dart';
import 'package:dedecube_startup/src/presentation/startup_success_page.dart';
import 'package:dedecube_startup/src/providers/startup_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that manages the startup flow of the application.
///
/// This widget handles three main states during startup:
/// - Loading: Shows a loading page while startup tasks are being performed
/// - Error: Displays an error page if startup fails, with retry capability
/// - Success: Renders the main application content once startup is complete
///
/// The widget uses [useReassemble] to handle hot reload scenarios by reinitializing
/// environment configurations and services.
class StartupContainer extends HookConsumerWidget {
  const StartupContainer({required this.startupProvider, super.key});

  final FutureProvider<void> startupProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      useStartupReassemble(ref);
    }

    final startupConfig = ref.watch(startupConfigNotifierProvider);
    final appStartupState = ref.watch(startupProvider);

    useStartupInitialization(ref, appStartupState);
    useInitializeCompleteCallback(ref, startupProvider);

    return appStartupState.when(
      loading: () => startupConfig.loadingPage ?? const StartupLoadingPage(),
      error: (error, stackTrace) =>
          startupConfig.errorPage ??
          StartupErrorPage(
            message: error.toString(),
            onRetry: () => ref.refresh(startupProvider),
          ),
      data: (_) => const StartupSuccessPage(),
    );
  }
}
