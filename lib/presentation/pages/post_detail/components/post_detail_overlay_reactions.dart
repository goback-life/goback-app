import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_mention_autocomplete.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_reactions.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reaction_picker_modal.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Arranges entries so the highest count sits in the middle,
/// with decreasing counts alternating left and right.
List<MapEntry<String, List<PostReactionModel>>> _centerSort(
  List<MapEntry<String, List<PostReactionModel>>> entries,
) {
  if (entries.length <= 1) return entries;
  final sorted = [...entries]
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final result = List<MapEntry<String, List<PostReactionModel>>?>.filled(
    sorted.length,
    null,
  );
  final mid = sorted.length ~/ 2;
  var left = mid, right = mid;
  for (var i = 0; i < sorted.length; i++) {
    if (i == 0) {
      result[mid] = sorted[i];
    } else if (i.isOdd) {
      left--;
      result[left] = sorted[i];
    } else {
      right++;
      result[right] = sorted[i];
    }
  }
  return result.cast<MapEntry<String, List<PostReactionModel>>>();
}

/// Horizontal reaction bar overlay for the post detail card.
///
/// Shows centered emoji pills sorted by popularity (highest in the
/// middle). Scrolls horizontally when pills overflow. The "+" button
/// opens an emoji picker bottom sheet.
class PostDetailOverlayReactions extends HookConsumerWidget {
  const PostDetailOverlayReactions({
    required this.postId,
    required this.scale,
    this.readOnly = false,
    super.key,
  });

  final String postId;
  final double scale;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = usePostReactions(ref, postId);
    final currentUserId = ref
        .watch(getCurrentUserProvider)
        .whenOrNull(data: (r) => r.fold((u) => u.id, (_) => null));

    final members = ref
        .watch(getCircleMembersProvider)
        .whenOrNull(data: (r) => r.fold((list) => list, (_) => null));
    final allUsers = useMentionAutocomplete(ref).allUsers;
    // Current user's profile for self-lookup (not in circle members list)
    final currentProfile = currentUserId != null
        ? ref
              .watch(getProfileProvider(currentUserId!))
              .whenOrNull(data: (r) => r.fold((p) => p, (_) => null))
        : null;
    String resolveName(String userId) {
      // Check current user first (not in circle members)
      if (userId == currentUserId && currentProfile != null) {
        return currentProfile.username;
      }
      if (members != null) {
        final m = members.where((m) => m.profile.id == userId).firstOrNull;
        if (m != null) return m.profile.username;
      }
      final u = allUsers.where((u) => u.id == userId).firstOrNull;
      if (u != null) return u.username;
      return userId.substring(0, 8);
    }

    final reactions =
        result.reactions.whenOrNull(
              data: (r) => r.fold((list) => list, (_) => <PostReactionModel>[]),
            )
            as List<PostReactionModel>? ??
        <PostReactionModel>[];

    // Group by emoji and center-sort
    final grouped = <String, List<PostReactionModel>>{};
    for (final r in reactions) {
      grouped.putIfAbsent(r.reaction, () => []).add(r);
    }
    final arranged = _centerSort(grouped.entries.toList());

    final pillH = 32.0 * scale;
    final pillRadius = pillH / 2;
    final gap = 10.0 * scale;
    final hPad = 16.0 * scale;
    final addW = 32.0 * scale;

    Widget addButton() => GestureDetector(
      onTap: readOnly ? null : () => _showPicker(context, result),
      child: Container(
        width: addW,
        height: pillH,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(pillRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 18 * scale,
              color: MainColors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );

    Widget buildPill(MapEntry<String, List<PostReactionModel>> entry) {
      final emoji = entry.key;
      final list = entry.value;
      final count = list.length;
      final isOwn = list.any((r) => r.userId == currentUserId);
      return GestureDetector(
        onTap: () {
          if (isOwn) {
            // Always allow removing own reaction
            result.removeReaction();
          } else if (!readOnly) {
            // Only allow adding new reactions when not read-only
            result.addReaction(emoji);
          }
        },
        onLongPress: () {
          final names = list.map((r) => resolveName(r.userId)).toList();
          _showReactors(context, emoji, names);
        },
        child: Container(
          height: pillH,
          padding: EdgeInsets.symmetric(horizontal: 10 * scale),
          decoration: BoxDecoration(
            color: isOwn
                ? MainColors.accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(pillRadius),
            border: Border.all(
              color: isOwn
                  ? MainColors.accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: 16 * scale)),
              SizedBox(width: 4 * scale),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  color: MainColors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: SizedBox(
        height: pillH,
        child: arranged.isEmpty
            ? (readOnly ? const SizedBox.shrink() : Center(child: addButton()))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < arranged.length; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            buildPill(arranged[i]),
                          ],
                          if (!readOnly) ...[SizedBox(width: gap), addButton()],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showPicker(BuildContext context, PostReactionsResult result) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmojiPickerSheet(
        scale: scale,
        onSelected: (emoji) {
          Navigator.pop(context);
          result.addReaction(emoji);
        },
      ),
    );
  }

  void _showReactors(BuildContext context, String emoji, List<String> names) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReactorListSheet(emoji: emoji, names: names, scale: scale),
    );
  }
}

/// Emoji picker bottom sheet with quick-picks and a text field for any emoji.
class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.scale, required this.onSelected});
  final double scale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12 * scale,
                runSpacing: 12 * scale,
                alignment: WrapAlignment.center,
                children: PostDetailReactionPickerModal.availableEmojis
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () => onSelected(emoji),
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 28 * scale),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 12 * scale),
              TextField(
                autofocus: false,
                style: TextStyle(fontSize: 24 * scale, color: Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Or type any emoji...',
                  hintStyle: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 10 * scale,
                  ),
                  counterText: '',
                ),
                maxLength: 2,
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    final emoji = text.characters.first;
                    onSelected(emoji);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet showing who reacted with a specific emoji.
class _ReactorListSheet extends StatelessWidget {
  const _ReactorListSheet({
    required this.emoji,
    required this.names,
    required this.scale,
  });
  final String emoji;
  final List<String> names;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$emoji Reactions',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w500,
                color: MainColors.white,
              ),
            ),
            SizedBox(height: 12 * scale),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: names.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(bottom: 8 * scale),
                  child: Text(
                    '@${names[i]}',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w400,
                      color: MainColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
