import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/widgets/loading/default_loading_overlay.dart';
import 'package:flutter/material.dart';

typedef LoadingOverlayBuilder = Widget Function(BuildContext context);

/// A hook that provides functionality for displaying a loading overlay.
/// The appearance can be customized by providing an [overlayBuilder].
///
/// The [context] parameter is optional and can be provided to specify the
/// BuildContext in which the overlay should be displayed. If not provided,
/// the hook will attempt to use the nearest available context.
///
/// Example usage:
/// ```dart
/// // With default overlay
/// final isLoading = useState(false);
/// useLoadingOverlay(isLoading, context: context);
/// ```
///
/// ```dart
/// // With custom overlay
/// useLoadingOverlay(
///   form.isSubmitting,
///   overlayBuilder: (context) => const MyCustomLoadingOverlay(),
///   context: context,
/// );
/// ```
void useLoadingOverlay(
  ValueNotifier<bool> shouldShow, {
  LoadingOverlayBuilder? overlayBuilder,
  BuildContext? context,
}) {
  final effectiveContext = context ?? useContext();

  OverlayEntry? overlayEntry;

  void hide() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }

  void listener() {
    if (!effectiveContext.mounted) {
      hide();
      return;
    }

    if (shouldShow.value) {
      hide(); // prevent duplicates

      overlayEntry = OverlayEntry(
        builder: (context) =>
            overlayBuilder?.call(context) ?? const DefaultLoadingOverlay(),
      );
      Overlay.of(effectiveContext).insert(overlayEntry!);
    } else {
      hide();
    }
  }

  useEffect(() {
    shouldShow.addListener(listener);
    return () {
      shouldShow.removeListener(listener);
      hide();
    };
  }, []);
}
