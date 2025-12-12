import 'dart:ui';

import 'package:cloudless/presentation/components/alerts/main_alert_layout.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

enum CallToActionType { primary, danger }

class MainAlert extends StatelessWidget with MainLayout, MainAlertLayout {
  const MainAlert({
    required this.title,
    required this.content,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.textButtonStyle,
    this.primaryButtonType = CallToActionType.danger,
    super.key,
    this.barrierDismissible = false,
  });

  final String title;
  final Widget content;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final TextStyle? textButtonStyle;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final CallToActionType primaryButtonType;
  final bool barrierDismissible;

  static Future<T?> showFull<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    TextStyle? textButtonStyle,
    bool barrierDismissible = false,
    CallToActionType primaryButtonType = CallToActionType.danger,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (context) => MainAlert(
      title: title,
      content: content,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      textButtonStyle: textButtonStyle,
      primaryButtonType: primaryButtonType,
      barrierDismissible: barrierDismissible,
    ),
  );

  static Future<T?> showSimple<T>({
    required BuildContext context,
    required String title,
    required String content,
    bool barrierDismissible = false,
  }) => showError<T>(
    context: context,
    title: title,
    content: content,
    buttonText: translator.translate('components.alert.confirm_button'),
    barrierDismissible: barrierDismissible,
  );

  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    bool barrierDismissible = false,
  }) => showFull<T>(
    context: context,
    title: title,
    content: Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      textAlign: TextAlign.center,
    ),
    primaryButtonText:
        buttonText ?? translator.translate('components.alert.confirm_button'),
    onPrimaryPressed: () => Navigator.of(context).pop(),
    barrierDismissible: barrierDismissible,
  );

  static Future<T?> showGenericError<T>({required BuildContext context}) =>
      showError<T>(
        context: context,
        title: translator.translate('components.alert.generic_error.title'),
        content: translator.translate('components.alert.generic_error.content'),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Container(
        color: colorScheme.onSurface.withValues(alpha: 0.1),
        child: Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalMargin,
              horizontal: horizontalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: titleToContent),

                content,

                SizedBox(height: contentToAction),

                Column(
                  children: [
                    ...switch ((secondaryButtonText, onSecondaryPressed)) {
                      (final String s, final VoidCallback p) => [
                        switch (primaryButtonType) {
                          CallToActionType.primary =>
                            CallToAction.primary.filled(
                              action: onPrimaryPressed,
                              label: Text(primaryButtonText),
                              horizontalMargin: horizontalMargin,
                              height: height,
                            ),
                          CallToActionType.danger => CallToAction.danger.filled(
                            action: onPrimaryPressed,
                            label: Text(primaryButtonText),
                            horizontalMargin: horizontalMargin,
                            height: height,
                          ),
                        },
                        SizedBox(height: spaceBetweenButtons),
                        CallToAction.primary.outlined(
                          action: p,
                          label: Text(s),
                          horizontalMargin: horizontalMargin,
                          height: height,
                        ),
                      ],
                      _ => [
                        CallToAction.primary.outlined(
                          action: onPrimaryPressed,
                          label: Text(primaryButtonText),
                          horizontalMargin: horizontalMargin,
                          height: height,
                        ),
                      ],
                    },
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
