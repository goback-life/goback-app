import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Horizontal scrollable row of @username pills for the post detail overlay.
class PostDetailOverlayTags extends StatelessWidget {
  const PostDetailOverlayTags({
    required this.usernames,
    required this.scale,
    this.userIds = const [],
    this.onTagTap,
    super.key,
  });

  final List<String> usernames;
  final List<String> userIds;
  final double scale;
  final void Function(String username, String userId)? onTagTap;

  @override
  Widget build(BuildContext context) {
    if (usernames.isEmpty) {
      return const SizedBox.shrink();
    }

    final pillRadius = 47.0 * scale;
    final fontSize = 15.0 * scale;
    final letterSpacing = -0.9 * scale;
    final hPad = 12.0 * scale;
    final vPad = 6.0 * scale;
    final gap = 8.0 * scale;

    return SizedBox(
      height: (fontSize + vPad * 2 + 4) * 1.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: usernames.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (_, i) {
          final tag = '@${usernames[i]}';
          return GestureDetector(
            onTap: () {
              final userId = i < userIds.length ? userIds[i] : '';
              onTagTap?.call(usernames[i], userId);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: vPad,
              ),
              decoration: BoxDecoration(
                color: MainColors.accent.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(pillRadius),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                  color: MainColors.white,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
