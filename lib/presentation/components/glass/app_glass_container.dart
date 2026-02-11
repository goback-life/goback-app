import 'dart:io';

import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Whether the device supports native Apple Liquid Glass (iOS 26+).
final bool kNativeGlassAvailable = _checkNativeGlass();

bool _checkNativeGlass() {
  if (!Platform.isIOS) return false;
  try {
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'^(\d+)\.').firstMatch(version);
    if (match == null) return false;
    return int.parse(match.group(1)!) >= 26;
  } catch (_) {
    return false;
  }
}

/// Wraps a subtree that contains [AppGlassContainer] widgets.
///
/// On Android / iOS < 26: provides a [LiquidGlassLayer] for shader compositing.
/// On iOS 26+: passthrough (native compositing is automatic).
///
/// Place one per page or per scrollable section — all [AppGlassContainer]
/// descendants will blend within the same compositing layer.
class AppGlassLayer extends StatelessWidget {
  const AppGlassLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kNativeGlassAvailable) return child;
    return LiquidGlassLayer(child: child);
  }
}

/// A platform-adaptive liquid glass surface.
///
/// - iOS 26+: native SwiftUI `.glassEffect()` via platform view.
/// - Android / iOS < 26: shader-based glass via [LiquidGlass].
///
/// Must be a descendant of [AppGlassLayer] on non-native platforms.
class AppGlassContainer extends StatelessWidget {
  const AppGlassContainer({
    super.key,
    required this.child,
    this.config = const GlassConfig(),
  });

  final Widget child;
  final GlassConfig config;

  @override
  Widget build(BuildContext context) {
    if (kNativeGlassAvailable) {
      return _NativeGlass(config: config, child: child);
    }
    return _ShaderGlass(config: config, child: child);
  }
}

/// iOS 26+ implementation using native SwiftUI platform view.
class _NativeGlass extends StatelessWidget {
  const _NativeGlass({required this.config, required this.child});

  final GlassConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: UiKitView(
              viewType: 'app_liquid_glass',
              creationParams: config.toCreationParams(),
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Android / iOS fallback using liquid_glass_renderer shaders.
class _ShaderGlass extends StatelessWidget {
  const _ShaderGlass({required this.config, required this.child});

  final GlassConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: Tune LiquidGlassSettings per-frame to match Figma visuals.
    // Default values provide a reasonable starting point.
    return LiquidGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: config.cornerRadius),
      child: child,
    );
  }
}
