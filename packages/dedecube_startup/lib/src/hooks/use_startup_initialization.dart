import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/src/providers/initialize_start_callback_provider.dart';
import 'package:flutter/material.dart';

void useStartupInitialization(WidgetRef ref, AsyncValue<void> startupState) {
  final initializeStartCallback = ref.watch(initializeStartCallbackProvider);
  final hasStarted = useRef(false);

  useEffect(() {
    if (startupState.isLoading && !hasStarted.value) {
      hasStarted.value = true;
      if (initializeStartCallback != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initializeStartCallback(ref);
        });
      }
    }
    return null;
  }, [startupState]);
}
