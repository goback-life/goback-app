import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class YourCircleFriendTile extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const YourCircleFriendTile({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onSwipeDelete,
  });

  final ProfileModel profile;
  final VoidCallback onTap;
  final VoidCallback onSwipeDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(profile.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onSwipeDelete();
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: MainColors.dark,
        child: Container(
          width: 60,
          height: friendTileHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFE13748),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.close, color: MainColors.white, size: 20),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: friendTileHeight,
          child: Row(
            children: [
              SizedBox(width: MediaQuery.of(context).size.width * 0.10),
              _Avatar(
                url: profile.avatarUrl,
                username: profile.username,
                size: friendAvatarSize,
              ),
              SizedBox(width: friendAvatarToText),
              Expanded(
                child: Text(
                  profile.username,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: friendTextSize,
                    color: MainColors.white,
                    letterSpacing: friendLetterSpacing,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.10,
                ),
                child: Text(
                  '>',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: friendTextSize,
                    color: MainColors.white,
                    letterSpacing: friendLetterSpacing,
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

/// Borderless circle avatar — no white ring.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.username,
    required this.size,
  });

  final String? url;
  final String username;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          memCacheWidth: (size * 2).toInt(),
          memCacheHeight: (size * 2).toInt(),
          placeholder: (_, __) => _fallback(context),
          errorWidget: (_, __, ___) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MainColors.accent,
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: size * 0.4,
            color: MainColors.white,
          ),
        ),
      ),
    );
  }
}
