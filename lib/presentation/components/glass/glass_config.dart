import 'package:flutter/material.dart';

/// Glass variant matching Apple's Liquid Glass types.
enum GlassVariant {
  /// Medium transparency, adapts to any content. Default for most UI.
  regular,

  /// High transparency for media-rich backgrounds.
  clear,
}

/// Path data for custom-shaped glass surfaces.
@immutable
class GlassPathData {
  const GlassPathData({
    required this.commands,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
  });

  /// Path commands: `['M', x, y]`, `['C', c1x, c1y, c2x, c2y, x, y]`,
  /// `['L', x, y]`, `['Z']`.
  final List<List<dynamic>> commands;
  final double viewBoxWidth;
  final double viewBoxHeight;
}

/// Configuration for a platform-adaptive liquid glass surface.
@immutable
class GlassConfig {
  const GlassConfig({
    this.variant = GlassVariant.regular,
    this.tint,
    this.cornerRadius = 24,
    this.interactive = false,
    this.pathData,
  });

  final GlassVariant variant;
  final Color? tint;
  final double cornerRadius;
  final bool interactive;
  final GlassPathData? pathData;

  /// Serialise to creation params for the iOS platform view.
  Map<String, dynamic> toCreationParams() {
    final t = tint;
    final pd = pathData;
    return {
      'variant': variant.name,
      if (t != null) 'tint': _colorToArgbInt(t),
      'cornerRadius': cornerRadius,
      'interactive': interactive,
      if (pd != null) ...{
        'pathCommands': pd.commands,
        'viewBoxWidth': pd.viewBoxWidth,
        'viewBoxHeight': pd.viewBoxHeight,
      },
    };
  }

  static int _colorToArgbInt(Color color) {
    final a = (color.a * 255).round();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}
