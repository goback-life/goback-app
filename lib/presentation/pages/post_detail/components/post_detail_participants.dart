import 'package:cloudless/core/features/lockout/domain/utilities/participant_distance.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

/// Displays lockout participants with distance-based tiers:
///
/// - Distance 1 (friends): `@username` -- tappable, navigates to full profile
/// - Distance 2 (friend of friend): `@username . friend of @X` -- tappable
/// - Distance 3+: collapsed as "and N others" -- not tappable
class PostDetailParticipants extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailParticipants({
    required this.participantIds,
    required this.participantUsernames,
    required this.participantAvatars,
    required this.participantJoinedVia,
    required this.myFriendIds,
    this.onFriendTap,
    this.onFriendOfFriendTap,
    super.key,
  });

  final List<String> participantIds;
  final List<String> participantUsernames;
  final List<String?> participantAvatars;
  final List<String?> participantJoinedVia;
  final Set<String> myFriendIds;
  final void Function(String userId, String username)? onFriendTap;
  final void Function(String userId, String username)? onFriendOfFriendTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (participantIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final d1Items = <_ParticipantItem>[];
    final d2Items = <_ParticipantItem>[];
    var d3Count = 0;

    for (var i = 0; i < participantIds.length; i++) {
      final id = participantIds[i];
      final username = i < participantUsernames.length
          ? participantUsernames[i]
          : 'unknown';
      final joinedVia = i < participantJoinedVia.length
          ? participantJoinedVia[i]
          : null;

      final distance = ParticipantDistance.compute(
        participantId: id,
        joinedVia: joinedVia,
        myFriendIds: myFriendIds,
      );

      switch (distance) {
        case 1:
          d1Items.add(_ParticipantItem(id: id, username: username));
        case 2:
          // Look up the joined_via username from participant list
          String? joinedViaUsername;
          if (joinedVia != null) {
            final joinedViaIndex = participantIds.indexOf(joinedVia);
            if (joinedViaIndex >= 0 &&
                joinedViaIndex < participantUsernames.length) {
              joinedViaUsername = participantUsernames[joinedViaIndex];
            }
          }
          d2Items.add(
            _ParticipantItem(
              id: id,
              username: username,
              joinedViaUsername: joinedViaUsername,
            ),
          );
        default:
          d3Count++;
      }
    }

    final baseStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.outlineVariant,
      fontWeight: FontWeight.w500,
      height: 20.5 / 14.0,
    );

    final children = <Widget>[];

    // Distance 1 items -- tappable friends
    for (var i = 0; i < d1Items.length; i++) {
      final item = d1Items[i];
      final isLast = i == d1Items.length - 1 && d2Items.isEmpty && d3Count == 0;
      children.add(
        GestureDetector(
          onTap: () => onFriendTap?.call(item.id, item.username),
          child: Text(
            '@${item.username}${isLast ? '' : ','}',
            style: baseStyle,
          ),
        ),
      );
    }

    // Distance 2 items -- friend of friend, tappable
    for (var i = 0; i < d2Items.length; i++) {
      final item = d2Items[i];
      final isLast = i == d2Items.length - 1 && d3Count == 0;
      final suffix = item.joinedViaUsername != null
          ? ' \u00b7 friend of @${item.joinedViaUsername}'
          : '';
      children.add(
        GestureDetector(
          onTap: () => onFriendOfFriendTap?.call(item.id, item.username),
          child: Text(
            '@${item.username}$suffix${isLast ? '' : ','}',
            style: baseStyle,
          ),
        ),
      );
    }

    // Distance 3+ -- collapsed count, not tappable
    if (d3Count > 0) {
      children.add(
        Text(
          'and $d3Count ${d3Count == 1 ? 'other' : 'others'}',
          style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.svg.tag.render(),
        SizedBox(width: tagSpacing),
        Expanded(
          child: Wrap(spacing: 4.0, runSpacing: 4.0, children: children),
        ),
      ],
    );
  }
}

class _ParticipantItem {
  const _ParticipantItem({
    required this.id,
    required this.username,
    this.joinedViaUsername,
  });

  final String id;
  final String username;
  final String? joinedViaUsername;
}
