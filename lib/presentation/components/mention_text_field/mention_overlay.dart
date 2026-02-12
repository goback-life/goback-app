import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

Widget _overlayAvatar(String? url, double size, {String? name}) {
  const bg = Color(0xFF555555);
  if (url != null && url.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
      placeholder: (_, __) => _overlayInitial(size, name, bg),
      errorWidget: (_, __, ___) => _overlayInitial(size, name, bg),
    );
  }
  return _overlayInitial(size, name, bg);
}

Widget _overlayInitial(double size, String? name, Color bg) {
  if (name != null && name.isNotEmpty) {
    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: MainColors.white,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
  return Container(width: size, height: size, color: bg);
}

/// Frosted-glass overlay that displays mention autocomplete suggestions.
class MentionOverlay extends StatelessWidget {
  const MentionOverlay({
    required this.layerLink,
    required this.users,
    required this.onUserSelected,
    super.key,
  });

  final LayerLink layerLink;
  final List<ProfileModel> users;
  final ValueChanged<ProfileModel> onUserSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 250,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 8),
        followerAnchor: Alignment.topLeft,
        targetAnchor: Alignment.bottomLeft,
        child: AppGlassContainer(
          config: const GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: 16,
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onUserSelected(user),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: ClipOval(
                              child: _overlayAvatar(user.avatarUrl, 32,
                                  name: user.username),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '@${user.username}',
                              style: const TextStyle(
                                fontFamily: MainFontFamilies.quicksand,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: MainColors.white,
                                decoration: TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
            ),
          ),
        ),
      ),
    );
  }
}
