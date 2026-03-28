import 'package:flutter/widgets.dart';

/// Lightweight lifecycle observer that fires a callback on state changes.
///
/// Used by lockout-related widgets to refresh data on app resume.
class LockoutLifecycleObserver extends WidgetsBindingObserver {
  LockoutLifecycleObserver(this.onStateChange);

  final void Function(AppLifecycleState) onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange(state);
  }
}
