import 'package:reactive_pin_code_fields/reactive_pin_code_fields.dart'
    as reactive;

/// Defines the animation type for pin code fields.
typedef FormerPinAnimationType = reactive.AnimationType;

/// Defines the haptic feedback type for pin code fields.
typedef FormerHapticFeedbackType = reactive.HapticFeedbackTypes;

/// Defines the error animation type for pin code fields.
typedef FormerErrorAnimationType = reactive.ErrorAnimationType;

/// Defines the configuration for pin dialogs.
typedef FormerPinDialogConfig = reactive.DialogConfig;

/// Defines the theme for pin code fields.
typedef FormerPinTheme = reactive.PinTheme;

/// Defines the shape for pin code fields.
typedef FormerPinCodeFieldShape = reactive.PinCodeFieldShape;

/// Provides default themes for pin code fields.
class FormerPinThemeDefaults {
  /// The default pin theme provided by the reactive library.
  static const FormerPinTheme defaults = reactive.PinTheme.defaults();

  /// The active pin theme derived from the default theme.
  static FormerPinTheme active = reactive.PinTheme(
    activeColor: const reactive.PinTheme.defaults().activeColor,
    selectedColor: const reactive.PinTheme.defaults().selectedColor,
    inactiveColor: const reactive.PinTheme.defaults().inactiveColor,
    activeFillColor: const reactive.PinTheme.defaults().activeFillColor,
    selectedFillColor: const reactive.PinTheme.defaults().selectedFillColor,
    inactiveFillColor: const reactive.PinTheme.defaults().inactiveFillColor,
    borderWidth: const reactive.PinTheme.defaults().borderWidth,
    borderRadius: const reactive.PinTheme.defaults().borderRadius,
    fieldHeight: const reactive.PinTheme.defaults().fieldHeight,
    fieldWidth: const reactive.PinTheme.defaults().fieldWidth,
    fieldOuterPadding: const reactive.PinTheme.defaults().fieldOuterPadding,
    shape: const reactive.PinTheme.defaults().shape,
    disabledColor: const reactive.PinTheme.defaults().disabledColor,
  );
}

/// Provides available animation types for pin code fields.
class FormerPinAnimationTypes {
  /// Slide animation type.
  static const FormerPinAnimationType slide = reactive.AnimationType.slide;

  /// Fade animation type.
  static const FormerPinAnimationType fade = reactive.AnimationType.fade;

  /// Scale animation type.
  static const FormerPinAnimationType scale = reactive.AnimationType.scale;

  /// No animation.
  static const FormerPinAnimationType none = reactive.AnimationType.none;
}

/// Provides available haptic feedback types for pin code fields.
class FormerHapticFeedbackTypes {
  /// Light haptic feedback.
  static const FormerHapticFeedbackType light =
      reactive.HapticFeedbackTypes.light;

  /// Medium haptic feedback.
  static const FormerHapticFeedbackType medium =
      reactive.HapticFeedbackTypes.medium;

  /// Heavy haptic feedback.
  static const FormerHapticFeedbackType heavy =
      reactive.HapticFeedbackTypes.heavy;

  /// Selection haptic feedback.
  static const FormerHapticFeedbackType selection =
      reactive.HapticFeedbackTypes.selection;

  /// Vibrate haptic feedback.
  static const FormerHapticFeedbackType vibrate =
      reactive.HapticFeedbackTypes.vibrate;
}

/// Provides available error animation types for pin code fields.
class FormerErrorAnimationTypes {
  /// Shake animation type for error indication.
  static const FormerErrorAnimationType shake =
      reactive.ErrorAnimationType.shake;
}

/// Provides available shapes for pin code fields.
class FormerPinCodeFieldShapes {
  /// Box-shaped pin code field.
  static const FormerPinCodeFieldShape box = reactive.PinCodeFieldShape.box;

  /// Underline-shaped pin code field.
  static const FormerPinCodeFieldShape underline =
      reactive.PinCodeFieldShape.underline;

  /// Circle-shaped pin code field.
  static const FormerPinCodeFieldShape circle =
      reactive.PinCodeFieldShape.circle;
}
