import 'dart:ui';

import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Horizontal floating strip that displays mention autocomplete suggestions
/// above the keyboard with a frosted glass background.
class MentionOverlay extends StatelessWidget {
  const MentionOverlay({
    required this.bottomInset,
    required this.users,
    required this.onUserSelected,
    super.key,
  });

  final double bottomInset;
  final List<ProfileModel> users;
  final ValueChanged<ProfileModel> onUserSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + 4,
      height: 44,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.7),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final user in users)
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onUserSelected(user),
                        child: Builder(
                          builder: (context) => Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontFamily: MainFontFamilies.quicksand,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
