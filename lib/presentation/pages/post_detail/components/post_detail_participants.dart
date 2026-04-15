import 'package:cloudless/core/features/lockout/domain/utilities/participant_distance.dart';
import 'package:flutter/material.dart';

/// Displays lockout participants as a horizontal scrollable list with
/// distance-based tiers:
///
/// - Distance 1 (friends): bold `@username` -- tappable
/// - Distance 2 (friend of friend): bold `@username` + lighter ` . via @X`
/// - Distance 3+: collapsed as "and N others" -- not tappable
class PostDetailParticipants extends StatelessWidget {
  const PostDetailParticipants({
    required this.participantIds,
    required this.participantUsernames,
    required this.participantAvatars,
    required this.participantJoinedVia,
    required this.myFriendIds,
    this.onFriendTap,
    this.onFriendOfFriendTap,
    this.textStyle,
    this.labelStyle,
    this.collapsedStyle,
    super.key,
  });

  final List<String> participantIds;
  final List<String> participantUsernames;
  final List<String?> participantAvatars;
  final List<String?> participantJoinedVia;
  final Set<String> myFriendIds;
  final void Function(String userId, String username)? onFriendTap;
  final void Function(String userId, String username, String? lockoutId)?
  onFriendOfFriendTap;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? collapsedStyle;

  @override
  Widget build(BuildContext context) {
    if (participantIds.isEmpty) return const SizedBox.shrink();

    final defaultStyle =
        textStyle ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.white,
        );
    final defaultLabel =
        labelStyle ??
        defaultStyle.copyWith(
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.6),
        );
    final defaultCollapsed =
        collapsedStyle ??
        defaultStyle.copyWith(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.5),
        );

    final d1 = <int>[];
    final d2 = <int>[];
    var d3Count = 0;

    for (var i = 0; i < participantIds.length; i++) {
      final d = ParticipantDistance.compute(
        participantId: participantIds[i],
        joinedVia: i < participantJoinedVia.length
            ? participantJoinedVia[i]
            : null,
        myFriendIds: myFriendIds,
      );
      if (d == 1) {
        d1.add(i);
      } else if (d == 2) {
        d2.add(i);
      } else {
        d3Count++;
      }
    }

    final items = <Widget>[];

    for (final i in d1) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      items.add(
        GestureDetector(
          onTap: () =>
              onFriendTap?.call(participantIds[i], participantUsernames[i]),
          child: Text('@${participantUsernames[i]}', style: defaultStyle),
        ),
      );
    }

    for (final i in d2) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      final jvId = participantJoinedVia[i];
      String? jvName;
      if (jvId != null) {
        final idx = participantIds.indexOf(jvId);
        if (idx >= 0) jvName = participantUsernames[idx];
      }
      items.add(
        GestureDetector(
          onTap: () => onFriendOfFriendTap?.call(
            participantIds[i],
            participantUsernames[i],
            null,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '@${participantUsernames[i]}',
                  style: defaultStyle,
                ),
                if (jvName != null)
                  TextSpan(text: ' \u00b7 via @$jvName', style: defaultLabel),
              ],
            ),
          ),
        ),
      );
    }

    if (d3Count > 0) {
      if (items.isNotEmpty) items.add(Text(', ', style: defaultLabel));
      items.add(
        Text(
          'and $d3Count other${d3Count == 1 ? '' : 's'}',
          style: defaultCollapsed,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}
