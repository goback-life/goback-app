import 'package:flutter/material.dart';

/// Glass variant matching Apple's Liquid Glass types.
enum GlassVariant {
  /// Medium transparency, adapts to any content. Default for most UI.
  regular,

  /// High transparency for media-rich backgrounds.
  clear,
}

/// Configuration for a platform-adaptive liquid glass surface.
@immutable
class GlassConfig {
  const GlassConfig({
    this.variant = GlassVariant.regular,
    this.tint,
    this.cornerRadius = 24,
    this.interactive = false,
  });

  final GlassVariant variant;
  final Color? tint;
  final double cornerRadius;
  final bool interactive;

  /// Serialise to creation params for the iOS platform view.
  Map<String, dynamic> toCreationParams() {
    final t = tint;
    return {
      'variant': variant.name,
      if (t != null) 'tint': _colorToArgbInt(t),
      'cornerRadius': cornerRadius,
      'interactive': interactive,
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
