import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Shows a liquid-glass confirmation dialog for removing a friend.
///
/// Returns `true` if the user confirmed removal, `false` otherwise.
Future<bool> showRemoveFriendDialog({
  required BuildContext context,
  required String username,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) => _RemoveDialogContent(username: username),
  );
  return result ?? false;
}

class _RemoveDialogContent extends StatelessWidget {
  const _RemoveDialogContent({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          child: AppGlassContainer(
            config: const GlassConfig(
              tint: MainColors.accent,
              cornerRadius: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remove $username?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: MainColors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: SizedBox(
                              height: 44,
                              child: AppGlassContainer(
                                config: const GlassConfig(
                                  tint: MainColors.accent,
                                  cornerRadius: 22,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: MainFontFamilies.quicksand,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: MainColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(true),
                            child: SizedBox(
                              height: 44,
                              child: AppGlassContainer(
                                config: const GlassConfig(
                                  tint: MainColors.accent,
                                  cornerRadius: 22,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontFamily: MainFontFamilies.quicksand,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: MainColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
