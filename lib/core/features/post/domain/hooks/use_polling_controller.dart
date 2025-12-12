import 'dart:async';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

typedef PollingControllerResult = ({
  bool isPollingActive,
  void Function() startPolling,
  void Function() stopPolling,
});

PollingControllerResult usePollingController({
  required VoidCallback onPoll,
  Duration interval = const Duration(seconds: 30),
}) {
  final isActive = useRef<bool>(false);
  final timer = useRef<Timer?>(null);
  final observer = useRef<_PollingLifecycleObserver?>(null);
  final wasActiveBeforePause = useRef<bool>(false);

  void startPolling() {
    if (isActive.value) {
      return;
    }

    isActive.value = true;
    timer.value?.cancel();

    timer.value = Timer.periodic(interval, (_) {
      if (isActive.value) {
        onPoll();
      }
    });
  }

  void stopPolling() {
    isActive.value = false;
    timer.value?.cancel();
    timer.value = null;
  }

  useEffect(() {
    // Create lifecycle observer
    observer.value = _PollingLifecycleObserver(
      onResumed: () {
        if (wasActiveBeforePause.value) {
          startPolling();
          onPoll();
        }
      },
      onPaused: () {
        if (isActive.value) {
          wasActiveBeforePause.value = true;
        }
        stopPolling();
      },
    );

    WidgetsBinding.instance.addObserver(observer.value!);

    return () {
      stopPolling();
      WidgetsBinding.instance.removeObserver(observer.value!);
      observer.value = null;
    };
  }, []);

  return (
    isPollingActive: isActive.value,
    startPolling: startPolling,
    stopPolling: stopPolling,
  );
}

class _PollingLifecycleObserver extends WidgetsBindingObserver {
  _PollingLifecycleObserver({required this.onResumed, required this.onPaused});

  final VoidCallback onResumed;
  final VoidCallback onPaused;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        onPaused();
        break;
    }
  }
}
