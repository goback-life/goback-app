part of '../assets.dart';

extension IconAssetsExtension on IconData {
  Widget render({
    Key? key,
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
    String? semanticLabel,
    TextDirection? textDirection,
    bool applyTextScaling = true,
    BlendMode? blendMode,
  }) {
    final Widget builtIcon = Icon(
      this,
      key: key,
      size: size,
      fill: fill,
      weight: weight,
      grade: grade,
      opticalSize: opticalSize,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      applyTextScaling: applyTextScaling,
      blendMode: blendMode,
    );
    return builtIcon;
  }
}
