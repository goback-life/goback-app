import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// A feed card displaying an active friend lockout as a placeholder.
///
/// Shows the goback logo, lockout info (time remaining/elapsed,
/// activity, location), and a "Join Lockout" button.
/// The timer updates every second for live countdown/countup.
class LockoutPlaceholderCard extends HookWidget {
  const LockoutPlaceholderCard({
    required this.session,
    required this.onJoinTap,
    super.key,
  });

  final LockoutSessionModel session;
  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final squircleSize = FeedLayout.squircleSize * s;
    final avatarSize = FeedLayout.avatarSize * s;
    final avatarInset = FeedLayout.avatarInsetFromSquircle * s;
    final avatarToName = FeedLayout.avatarToNameGap * s;
    final squircleToAuthor = FeedLayout.squircleToAuthorGap * s;
    final fontSize = FeedLayout.usernameFontSize * s;
    final letterSpacing = FeedLayout.usernameLetterSpacing * s;
    final nameMaxW = FeedLayout.nameMaxWidth(screenWidth);
    final leftInset = FeedLayout.leftPostInset * s;

    final displayName = session.username ?? 'Unknown';

    // Live timer — rebuilds every second
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, []);

    final timeText = _buildTimeText(now.value);
    final infoLines = _buildInfoLines();

    return Padding(
      padding: EdgeInsets.only(left: leftInset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: squircleSize,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Squircle with goback logo + lockout info
              GestureDetector(
                onTap: onJoinTap,
                child: SizedBox(
                  width: squircleSize,
                  height: squircleSize,
                  child: ClipSquircle(
                    child: Container(
                      color: MainColors.dark,
                      child: Stack(
                        children: [
                          // Goback logo centered
                          Center(
                            child: Image.asset(
                              'assets/images/pngs/app_icon_foreground.png',
                              width: squircleSize * 0.4,
                              height: squircleSize * 0.4,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Info overlay at bottom
                          Positioned(
                            left: 12 * s,
                            right: 12 * s,
                            bottom: 12 * s,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Time display
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontFamily: MainFontFamilies.quicksand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18 * s,
                                    color: Colors.white,
                                    letterSpacing: -0.5 * s,
                                  ),
                                ),
                                if (infoLines.isNotEmpty) ...[
                                  SizedBox(height: 4 * s),
                                  ...infoLines.map(
                                    (line) => Padding(
                                      padding: EdgeInsets.only(top: 2 * s),
                                      child: Text(
                                        line,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily:
                                              MainFontFamilies.quicksand,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13 * s,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          letterSpacing: -0.3 * s,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: squircleToAuthor),

              // Author row + join button
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 6 * s,
                  horizontal: avatarInset,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child: ClipOval(
                        child:
                            (session.avatarUrl != null &&
                                session.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: session.avatarUrl!,
                                fit: BoxFit.cover,
                                width: avatarSize,
                                height: avatarSize,
                                memCacheWidth: (avatarSize * 2).toInt(),
                                memCacheHeight: (avatarSize * 2).toInt(),
                                placeholder: (_, __) => Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                ),
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                              ),
                      ),
                    ),
                    SizedBox(width: avatarToName),
                    // Username
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: nameMaxW),
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w400,
                            fontSize: fontSize,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: letterSpacing,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    // Join button
                    GestureDetector(
                      onTap: onJoinTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * s,
                          vertical: 6 * s,
                        ),
                        decoration: BoxDecoration(
                          color: MainColors.dark,
                          borderRadius: BorderRadius.circular(16 * s),
                        ),
                        child: Text(
                          'Join',
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * s,
                            color: Colors.white,
                            letterSpacing: -0.3 * s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeText(DateTime now) {
    if (session.isOpenEnded) {
      // Venue: count up from start
      final elapsed = now.difference(session.startedAt);
      return _formatDuration(elapsed);
    } else {
      // Timed: count down to end
      final remaining = session.endsAt.difference(now);
      if (remaining.isNegative) {
        return '0:00';
      }
      return _formatDuration(remaining);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  List<String> _buildInfoLines() {
    final lines = <String>[];
    if (session.actionText != null && session.actionText!.isNotEmpty) {
      lines.add(session.actionText!);
    }
    if (session.locationName != null && session.locationName!.isNotEmpty) {
      lines.add(session.locationName!);
    }
    return lines;
  }
}
