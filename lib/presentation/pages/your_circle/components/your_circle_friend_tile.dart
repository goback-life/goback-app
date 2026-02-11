import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
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
              SizedBox(width: friendTileLeftIndent),
              ProfileImage(
                imageUrl: profile.avatarUrl,
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
                padding: EdgeInsets.only(right: friendChevronRightPad),
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
