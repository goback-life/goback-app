import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/connection/data/dtos/leaderboard_entry_dto.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class LeaderboardTile extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const LeaderboardTile({
    super.key,
    required this.entry,
    required this.rank,
    this.onTap,
    this.onSwipeDelete,
    this.isRemoveMode = false,
    this.isSelected = false,
    this.onToggle,
  });

  final LeaderboardEntryDto entry;
  final int rank;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeDelete;
  final bool isRemoveMode;
  final bool isSelected;
  final VoidCallback? onToggle;

  static const Color _gold = Color(0xFFFFD700);

  bool get _isKing => rank == 1 && entry.sessionCount > 0;
  bool get _isInactive => entry.sessionCount == 0;
  bool get _isCurrentUser => entry.isCurrentUser;

  static String _formatDuration(double minutes) {
    final totalMinutes = minutes.round();
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: isRemoveMode ? onToggle : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _isKing ? kingTileHeight : friendTileHeight,
        child: Stack(
          children: [
            // Accent bar for current user or king
            if (_isCurrentUser && !_isKing)
              Positioned(
                left:
                    MediaQuery.of(context).size.width * 0.10 -
                    accentBarLeftOffset,
                top: (friendTileHeight - accentBarHeight) / 2,
                child: Container(
                  width: accentBarWidth,
                  height: accentBarHeight,
                  decoration: BoxDecoration(
                    color: MainColors.accent.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (_isKing)
              Positioned(
                left:
                    MediaQuery.of(context).size.width * 0.10 -
                    accentBarLeftOffset,
                top: (kingTileHeight - kingAccentBarHeight) / 2,
                child: Container(
                  width: accentBarWidth,
                  height: kingAccentBarHeight,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            // Main row
            Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.10),
                // Rank number or crown
                SizedBox(
                  width: rankWidth,
                  child: _isKing
                      ? Text(
                          '\u2654',
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _gold.withValues(alpha: 0.5),
                          ),
                        )
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: MainColors.white.withValues(alpha: 0.25),
                            letterSpacing: -0.5,
                          ),
                        ),
                ),
                SizedBox(width: rankRightMargin),
                // Avatar
                _Avatar(
                  url: entry.avatarUrl,
                  username: entry.username,
                  size: _isKing ? kingAvatarSize : friendAvatarSize,
                  isKing: _isKing,
                  isInactive: _isInactive,
                ),
                SizedBox(width: friendAvatarToText),
                // Username
                Expanded(
                  child: Text(
                    _isCurrentUser ? 'you' : entry.username,
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: _isKing || _isCurrentUser
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: friendTextSize,
                      color: _usernameColor,
                      letterSpacing: friendLetterSpacing,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Right side: duration or checkbox
                Padding(
                  padding: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width * 0.10,
                  ),
                  child: isRemoveMode
                      ? _Checkbox(
                          isSelected: isSelected,
                          size: checkboxSize,
                          radius: checkboxRadius,
                        )
                      : _DurationOrDash(
                          entry: entry,
                          isKing: _isKing,
                          isCurrentUser: _isCurrentUser,
                          formatDuration: _formatDuration,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isRemoveMode) {
      return tile;
    }

    return Dismissible(
      key: ValueKey(entry.userId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onSwipeDelete?.call();
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.close, color: MainColors.white, size: 20),
      ),
      child: tile,
    );
  }

  Color get _usernameColor {
    if (_isKing) {
      return _gold.withValues(alpha: 0.75);
    }
    if (_isCurrentUser) {
      return MainColors.accent;
    }
    if (_isInactive) {
      return MainColors.white.withValues(alpha: 0.4);
    }
    return MainColors.white;
  }
}

// ---------------------------------------------------------------------------

class _DurationOrDash extends StatelessWidget {
  const _DurationOrDash({
    required this.entry,
    required this.isKing,
    required this.isCurrentUser,
    required this.formatDuration,
  });

  final LeaderboardEntryDto entry;
  final bool isKing;
  final bool isCurrentUser;
  final String Function(double) formatDuration;

  static const Color _gold = Color(0xFFFFD700);

  bool get _isInactive => entry.sessionCount == 0;

  @override
  Widget build(BuildContext context) {
    if (_isInactive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\u2014',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: MainColors.white.withValues(alpha: 0.25),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'no sessions',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: MainColors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      );
    }

    final minutes = entry.avgDurationMinutes ?? 0.0;
    final label = formatDuration(minutes);

    Color durationColor;
    FontWeight durationWeight;
    if (isKing) {
      durationColor = _gold.withValues(alpha: 0.6);
      durationWeight = FontWeight.w600;
    } else if (isCurrentUser) {
      durationColor = MainColors.accent.withValues(alpha: 0.7);
      durationWeight = FontWeight.w500;
    } else {
      durationColor = MainColors.white.withValues(alpha: 0.5);
      durationWeight = FontWeight.w500;
    }

    return Text(
      label,
      style: TextStyle(
        fontFamily: MainFontFamilies.quicksand,
        fontWeight: durationWeight,
        fontSize: 14,
        color: durationColor,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.username,
    required this.size,
    required this.isKing,
    required this.isInactive,
  });

  final String? url;
  final String username;
  final double size;
  final bool isKing;
  final bool isInactive;

  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (url != null && url!.isNotEmpty) {
      avatar = ClipOval(
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
    } else {
      avatar = _fallback(context);
    }

    if (isKing) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: _gold.withValues(alpha: 0.12), blurRadius: 20),
          ],
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _fallback(BuildContext context) {
    final bgColor = isInactive
        ? MainColors.accent.withValues(alpha: 0.3)
        : MainColors.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
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

// ---------------------------------------------------------------------------

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.isSelected,
    required this.size,
    required this.radius,
  });

  final bool isSelected;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? MainColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isSelected
              ? MainColors.accent
              : MainColors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
    );
  }
}
