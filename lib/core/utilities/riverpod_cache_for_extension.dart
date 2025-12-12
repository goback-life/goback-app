import 'dart:async';

import 'package:dedecube_core/dedecube_core.dart';

// Ref: https://riverpod.dev/docs/concepts2/auto_dispose#example-keeping-state-alive-for-a-specific-amount-of-time
extension RiverpodCacheForExtension on Ref {
  /// Keeps the provider alive for [duration].
  void cacheFor(Duration duration) {
    // Immediately prevent the state from getting destroyed.
    final link = keepAlive();
    // After duration has elapsed, we re-enable automatic disposal.
    final timer = Timer(duration, link.close);

    // When the provider is recomputed (such as with ref.watch),
    // we cancel the pending timer.
    onDispose(timer.cancel);
  }
}
