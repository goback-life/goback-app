import 'dart:ui' as ui;

import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// A red-tinted frosted glass toast for warnings and errors.
///
/// Uses BackdropFilter with a red tint overlay, matching the app's
/// liquid glass aesthetic. Auto-dismisses after [duration].
class GlassWarningToast extends StatelessWidget {
  const GlassWarningToast({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback onDismiss;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopSnackBar(
      Overlay.of(context),
      GlassWarningToast(
        message: message,
        onDismiss: () {},
      ),
      displayDuration: duration,
      dismissType: DismissType.onSwipe,
      dismissDirection: [DismissDirection.up],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFE13748).withValues(alpha: 0.18),
            border: Border.all(
              color: const Color(0xFFE13748).withValues(alpha: 0.35),
              width: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE13748).withValues(alpha: 0.22),
                const Color(0xFFE13748).withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
