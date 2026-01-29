import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hook that triggers a callback when the app resumes from background.
/// Used to refresh data (like avatars) when user returns to the app.
/// Includes a 60-second debounce to prevent rapid successive refreshes.
void useAppResumeRefresh({
  required VoidCallback onResume,
  Duration debounce = const Duration(seconds: 60),
}) {
  final lastRefreshTime = useRef<DateTime?>(null);
  final observer = useRef<_AppResumeObserver?>(null);

  useEffect(() {
    observer.value = _AppResumeObserver(
      onResume: () {
        final now = DateTime.now();
        final lastRefresh = lastRefreshTime.value;

        // Skip if last refresh was within debounce period
        if (lastRefresh != null && now.difference(lastRefresh) < debounce) {
          final elapsed = now.difference(lastRefresh);
          debugPrint(
            '[AppResumeRefresh] Skipped - last refresh ${elapsed.inSeconds}s ago (debounce: ${debounce.inSeconds}s)',
          );
          return;
        }

        debugPrint(
          '[AppResumeRefresh] Triggering refresh (last: ${lastRefresh?.toIso8601String() ?? "never"})',
        );
        lastRefreshTime.value = now;
        onResume();
      },
    );
    WidgetsBinding.instance.addObserver(observer.value!);

    return () {
      WidgetsBinding.instance.removeObserver(observer.value!);
      observer.value = null;
    };
  }, []);
}

class _AppResumeObserver extends WidgetsBindingObserver {
  _AppResumeObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
