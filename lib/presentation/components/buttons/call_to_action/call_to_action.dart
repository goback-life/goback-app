import 'dart:ui';

import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

part 'components/styled_child.dart';
part 'theming/call_to_action_mode.dart';
part 'theming/call_to_action_style.dart';
part 'theming/call_to_action_theme.dart';
part 'theming/decoration.dart';
part 'theming/mode_to_theme.dart';
part 'theming/theme_to_mode.dart';

class CallToAction extends StatelessWidget {
  const CallToAction({
    required this.action,
    required this.label,
    this.mode,
    this.theme,
    super.key,
    this.icon,
    this.onLongPress,
    this.secondaryIcon,
    this.horizontalMargin,
    this.iconOnTheRight,
    this.spaced,
    this.height,
    this.borderRadius,
    this.duration,
    this.curve,
  });

  static const primary = PrimaryCallToActionTheme();
  static const secondary = SecondaryCallToActionTheme();
  static const tertiary = TertiaryCallToActionTheme();
  static const danger = DangerCallToActionTheme();
  static const standard = RegularCallToActionTheme();

  static const filled = CallToActionMode.filled;
  static const empty = CallToActionMode.empty;
  static const outlined = CallToActionMode.outlined;
  static const filledOutlined = CallToActionMode.filledOutlined;

  final VoidCallback? action;
  final VoidCallback? onLongPress;
  final Widget label;
  final Widget? icon;
  final Widget? secondaryIcon;
  final bool? iconOnTheRight;
  final bool? spaced;
  final BorderRadius? borderRadius;
  final CallToActionMode? mode;
  final CallToActionTheme? theme;
  final double? height;
  final double? horizontalMargin;

  final Duration? duration;
  final Curve? curve;

  @override
  Widget build(BuildContext context) {
    final themeData = context.theme;

    final CallToActionStyle callToActionStyle =
        themeData.extension<CallToActionStyle>() ??
        CallToActionStyle.defaultStyle;

    final bool iconOnTheRight =
        this.iconOnTheRight ?? callToActionStyle.iconOnTheRight;
    final bool spaced = this.spaced ?? callToActionStyle.spaced;
    final BorderRadius borderRadius =
        this.borderRadius ?? callToActionStyle.borderRadius;
    final CallToActionMode mode = this.mode ?? callToActionStyle.mode;
    final CallToActionTheme theme = this.theme ?? callToActionStyle.theme;
    final double height = this.height ?? callToActionStyle.height;
    final double horizontalMargin =
        this.horizontalMargin ?? callToActionStyle.horizontalMargin;
    final Duration duration = this.duration ?? callToActionStyle.duration;
    final Curve curve = this.curve ?? callToActionStyle.curve;

    final colors = action == null
        ? theme.getInactiveColors(context, themeData, mode)
        : theme.getActiveColors(context, themeData, mode);

    final isDisabled = action == null;
    final hasBorder =
        mode == CallToActionMode.outlined ||
        mode == CallToActionMode.filledOutlined;
    final isTransparent = mode == CallToActionMode.empty;
    final radius = borderRadius.topLeft.x;

    final glassConfig = GlassConfig(
      variant: GlassVariant.clear,
      cornerRadius: radius,
      tint: colors.background,
      opacity: isDisabled ? 0.2 : 0.35,
    );

    Widget content = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: _CallToActionStyledChild(
                foreground: colors.foreground,
                child: switch ((spaced, icon)) {
                  (false, final Widget icon) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Opacity(opacity: 0, child: icon), label, icon]
                        .separateWith(const CustomSpace.horizontal(8))
                        .reversedList(!iconOnTheRight),
                  ),
                  _ => label,
                },
              ),
            ),
          ),
          if (spaced)
            if (icon case final Widget icon)
              Positioned(
                right: iconOnTheRight ? 0 : null,
                left: !iconOnTheRight ? 0 : null,
                width: kToolbarHeight,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CallToActionStyledChild(
                    foreground: colors.foreground,
                    child: icon,
                  ),
                ),
              ),
          if (secondaryIcon case final Widget secondary)
            Positioned(
              right: !iconOnTheRight ? 0 : null,
              left: iconOnTheRight ? 0 : null,
              width: kToolbarHeight,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CallToActionStyledChild(
                  foreground: colors.foreground,
                  child: secondary,
                ),
              ),
            ),
        ],
      ),
    );

    if (hasBorder) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: colors.outline),
        ),
        child: content,
      );
    }

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: action != null
              ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  action?.call();
                }
              : null,
          onLongPress: onLongPress,
          child: AppGlassContainer(config: glassConfig, child: content),
        ),
      ),
    );
  }

  static Decoration decoration({
    required CTAColors colors,
    required CallToActionMode mode,
    required BorderRadius borderRadius,
  }) {
    return ShapeDecoration(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: switch (mode) {
          CallToActionMode.filledOutlined || CallToActionMode.outlined =>
            BorderSide(width: 1, color: colors.outline),
          _ => BorderSide.none,
        },
      ),
      color: colors.background,
    );
  }
}

extension _ReversedList<T> on List<T> {
  // ignore: avoid_positional_boolean_parameters
  List<T> reversedList(bool apply) => apply ? reversed.toList() : this;
}
