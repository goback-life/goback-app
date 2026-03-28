import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Shared profile avatar — DRYs up the 3 duplicated avatar patterns
// ---------------------------------------------------------------------------

class ConnectionProfileAvatar extends StatelessWidget {
  const ConnectionProfileAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.radius = 20,
  });

  final String username;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: MainColors.accent.withValues(alpha: 0.2),
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: MainColors.white,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small action button (Connect, Accept, Pending, etc.)
// ---------------------------------------------------------------------------

class SmallActionButton extends StatelessWidget {
  const SmallActionButton({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header (Incoming / Sent)
// ---------------------------------------------------------------------------

class RequestSectionHeader extends StatelessWidget {
  const RequestSectionHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: MainColors.white.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incoming request tile
// ---------------------------------------------------------------------------

class IncomingRequestTile extends StatelessWidget {
  const IncomingRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDeny,
    required this.isCircleFull,
  });

  final ConnectionRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDeny;
  final bool isCircleFull;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ConnectionProfileAvatar(
            username: request.profile.username,
            avatarUrl: request.profile.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.profile.username,
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: MainColors.white,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SmallActionButton(
            label: isCircleFull ? 'Full' : 'Accept',
            color: isCircleFull
                ? MainColors.white.withValues(alpha: 0.3)
                : MainColors.accent,
            onTap: isCircleFull ? null : onAccept,
          ),
          const SizedBox(width: 8),
          SmallActionButton(
            label: 'Deny',
            color: MainColors.white.withValues(alpha: 0.3),
            onTap: onDeny,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outgoing request tile
// ---------------------------------------------------------------------------

class OutgoingRequestTile extends StatelessWidget {
  const OutgoingRequestTile({
    super.key,
    required this.request,
    required this.onCancel,
  });

  final ConnectionRequestModel request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ConnectionProfileAvatar(
            username: request.profile.username,
            avatarUrl: request.profile.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.profile.username,
                  style: const TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: MainColors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatRelativeTime(request.createdAt),
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontSize: 13,
                    color: MainColors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close,
              size: 20,
              color: MainColors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search result tile
// ---------------------------------------------------------------------------

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.profile,
    required this.status,
    required this.onConnect,
    required this.onAccept,
    required this.isCircleFull,
  });

  final ProfileModel profile;
  final ConnectionStatus status;
  final VoidCallback onConnect;
  final VoidCallback onAccept;
  final bool isCircleFull;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ConnectionProfileAvatar(
            username: profile.username,
            avatarUrl: profile.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              profile.username,
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: MainColors.white,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final disabledColor = MainColors.white.withValues(alpha: 0.3);
    switch (status) {
      case ConnectionStatus.none:
        return SmallActionButton(
          label: isCircleFull ? 'Full' : 'Connect',
          color: isCircleFull ? disabledColor : MainColors.accent,
          onTap: isCircleFull ? null : onConnect,
        );
      case ConnectionStatus.pendingOutgoing:
        return SmallActionButton(
          label: 'Pending',
          color: disabledColor,
        );
      case ConnectionStatus.pendingIncoming:
        return SmallActionButton(
          label: isCircleFull ? 'Full' : 'Accept',
          color: isCircleFull ? disabledColor : MainColors.accent,
          onTap: isCircleFull ? null : onAccept,
        );
      case ConnectionStatus.connected:
        return SmallActionButton(
          label: 'Connected',
          color: disabledColor,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Relative time formatting
// ---------------------------------------------------------------------------

String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();
  final diff = now.difference(local);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inHours < 48) return 'Yesterday';
  return DateFormat.MMMd().format(local);
}
