import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/src/providers/initialize_complete_callback_provider.dart';
import 'package:flutter/material.dart';

/// Hook that handles the initialize complete callback
void useInitializeCompleteCallback(
  WidgetRef ref,
  FutureProvider<void> startupProvider,
) {
  final initializeCompleteCallback = ref.watch(
    initializeCompleteCallbackProvider,
  );

  useEffect(() {
    final subscription = ref.listenManual<AsyncValue<void>>(startupProvider, (
      previous,
      next,
    ) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (initializeCompleteCallback != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.microtask(() {
              try {
                initializeCompleteCallback(ref, next.hasValue);
              } catch (e) {
                debugPrint('Error in initialize complete callback: $e');
                Future.delayed(const Duration(milliseconds: 100), () {
                  initializeCompleteCallback(ref, next.hasValue);
                });
              }
            });
          });
        }
      }
    });

    return () {
      subscription.close();
    };
  }, [startupProvider]);
}
