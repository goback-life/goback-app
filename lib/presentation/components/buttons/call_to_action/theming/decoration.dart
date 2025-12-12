part of '../call_to_action.dart';

extension CTAThemeToDecoration on CallToActionTheme {
  Decoration decoration({
    required BuildContext context,
    required bool active,
    required CallToActionMode mode,
    required BorderRadius borderRadius,
  }) =>
      CallToAction.decoration(
        mode: mode,
        borderRadius: borderRadius,
        colors: active
            ? getActiveColors(context, context.theme, mode)
            : getInactiveColors(context, context.theme, mode),
      );
}
