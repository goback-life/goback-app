import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/goback_logo.dart';
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

    final colorScheme = Theme.of(context).colorScheme;
    final displayName = session.username ?? 'Unknown';

    // DEBUG: check avatar URL
    debugPrint('[PlaceholderCard] avatarUrl=${session.avatarUrl}');

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
    final participantCount = session.participants.length;

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
              // Squircle with glass background + goback triangle logo
              GestureDetector(
                onTap: onJoinTap,
                child: SizedBox(
                  width: squircleSize,
                  height: squircleSize,
                  child: ClipSquircle(
                    child: AppGlassContainer(
                      config: GlassConfig(
                        cornerRadius: 0,
                        tint: MainColors.accent.withValues(alpha: 0.15),
                      ),
                      child: Stack(
                        children: [
                          // Goback triangle logo centered
                          Center(
                            child: GobackLogo(
                              fontSize: squircleSize * 0.18,
                              textColor: Colors.white,
                              triangleColor: MainColors.accent,
                            ),
                          ),
                          // Time + activity overlay at bottom
                          Positioned(
                            left: 12 * s,
                            right: 12 * s,
                            bottom: 12 * s,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontFamily: MainFontFamilies.quicksand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18 * s,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5 * s,
                                  ),
                                ),
                                if (infoLines.isNotEmpty) ...[
                                  SizedBox(width: 8 * s),
                                  Expanded(
                                    child: Text(
                                      infoLines.join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: MainFontFamilies.quicksand,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13 * s,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                        letterSpacing: -0.3 * s,
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
                                  color: colorScheme.surfaceContainerHigh,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: colorScheme.surfaceContainerHigh,
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerHigh,
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
                            color: colorScheme.onSurface,
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
                          color: MainColors.accent,
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

              // Participant count
              if (participantCount > 0) ...[
                SizedBox(height: 4 * s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: avatarInset),
                  child: Text(
                    participantCount == 1
                        ? '1 other person joined'
                        : '$participantCount others joined',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w400,
                      fontSize: 13 * s,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: -0.3 * s,
                    ),
                  ),
                ),
              ],
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
