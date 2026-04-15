part of '../call_to_action.dart';

class CallToActionStyle extends ThemeExtension<CallToActionStyle> {
  const CallToActionStyle({
    required this.mode,
    required this.theme,
    this.horizontalMargin = 12,
    this.iconOnTheRight = true,
    this.spaced = true,
    this.height = kToolbarHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.duration = Durations.medium4,
    this.curve = Easings.standard,
  });

  final bool iconOnTheRight;
  final bool spaced;
  final BorderRadius borderRadius;
  final CallToActionMode mode;
  final CallToActionTheme theme;
  final double height;
  final double horizontalMargin;

  final Duration duration;
  final Curve curve;

  static const CallToActionStyle defaultStyle = CallToActionStyle(
    horizontalMargin: 12,
    iconOnTheRight: true,
    spaced: true,
    height: kToolbarHeight,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    duration: Durations.medium4,
    curve: Easings.standard,
    mode: CallToActionMode.filled,
    theme: CallToActionTheme.primary,
  );

  @override
  CallToActionStyle copyWith({
    bool? iconOnTheRight,
    bool? spaced,
    BorderRadius? borderRadius,
    CallToActionMode? mode,
    CallToActionTheme? theme,
    double? height,
    double? horizontalMargin,
    Duration? duration,
    Curve? curve,
  }) {
    return CallToActionStyle(
      iconOnTheRight: iconOnTheRight ?? this.iconOnTheRight,
      spaced: spaced ?? this.spaced,
      borderRadius: borderRadius ?? this.borderRadius,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
      height: height ?? this.height,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }

  @override
  CallToActionStyle lerp(CallToActionStyle? other, double t) {
    if (other is! CallToActionStyle) {
      return this;
    }
    return CallToActionStyle(
      iconOnTheRight: t >= 0.5 ? other.iconOnTheRight : iconOnTheRight,
      spaced: t >= 0.5 ? other.spaced : spaced,
      borderRadius:
          BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
          borderRadius,
      mode: t >= 0.5 ? other.mode : mode,
      theme: t >= 0.5 ? other.theme : theme,
      height: lerpDouble(height, other.height, t) ?? other.height,
      horizontalMargin:
          lerpDouble(horizontalMargin, other.horizontalMargin, t) ??
          other.horizontalMargin,
      duration: Duration(
        microseconds:
            (lerpDouble(
                      duration.inMicroseconds,
                      other.duration.inMicroseconds,
                      t,
                    ) ??
                    other.duration.inMicroseconds)
                .round(),
      ),
      curve: t >= 0.5 ? other.curve : curve,
    );
  }
}
