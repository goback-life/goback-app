import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Hook that provides mention autocomplete functionality.
///
/// Returns:
/// - [allUsers]: List of all circle members available for mentioning
/// - [isLoading]: Whether the member list is still loading
/// - [parseMentions]: Function to extract @mentioned user IDs from text
MentionAutocompleteState useMentionAutocomplete(WidgetRef ref) {
  final membersAsync = ref.watch(getCircleMembersProvider);

  final allUsers = useMemoized(() {
    return membersAsync.maybeWhen(
      data: (result) => result.fold(
        (members) => members.map((m) => m.profile).toList(),
        (_) => <ProfileModel>[],
      ),
      orElse: () => <ProfileModel>[],
    );
  }, [membersAsync]);

  /// Parses text and extracts user IDs for all valid @mentions.
  List<String> parseMentions(String text) {
    final mentions = <String>[];
    final pattern = RegExp(r'@(\w+)');
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final username = match.group(1)?.toLowerCase();
      if (username == null) continue;

      final user = allUsers.firstWhere(
        (u) => u.username.toLowerCase() == username,
        orElse: () => const ProfileModel(id: '', username: ''),
      );

      if (user.id.isNotEmpty && !mentions.contains(user.id)) {
        mentions.add(user.id);
      }
    }

    return mentions;
  }

  return MentionAutocompleteState(
    allUsers: allUsers,
    isLoading: membersAsync.isLoading,
    parseMentions: parseMentions,
  );
}

/// State returned by [useMentionAutocomplete].
class MentionAutocompleteState {
  const MentionAutocompleteState({
    required this.allUsers,
    required this.isLoading,
    required this.parseMentions,
  });

  final List<ProfileModel> allUsers;
  final bool isLoading;
  final List<String> Function(String text) parseMentions;
}
