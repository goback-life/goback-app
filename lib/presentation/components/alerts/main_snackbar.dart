import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MainSnackbar extends StatelessWidget with MainLayout, MainSnackbarLayout {
  const MainSnackbar({
    required this.message,
    required this.isError,
    required this.colorScheme,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final bool isError;
  final ColorScheme colorScheme;
  final VoidCallback onDismiss;

  static AnimationController? _currentController;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showTopSnackBar(
      Overlay.of(context),
      MainSnackbar(
        message: message,
        isError: isError,
        colorScheme: colorScheme,
        onDismiss: () => _currentController?.reverse(),
      ),
      displayDuration: duration,
      dismissType: DismissType.onSwipe,
      dismissDirection: [DismissDirection.up],
      onAnimationControllerInit: (controller) =>
          _currentController = controller,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: EdgeInsets.all(allPadding),
      decoration: BoxDecoration(
        color: isError ? MainColors.red100 : MainColors.green100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          isError ? Assets.svg.error.render() : Assets.svg.success.render(),
          SizedBox(width: iconToMessage),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(onTap: onDismiss, child: Assets.svg.close.render()),
        ],
      ),
    );
  }
}
