import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class CircleMembersData {
  const CircleMembersData({
    required this.groupedMembers,
    required this.searchQuery,
    required this.updateSearchQuery,
    required this.allUsers,
    required this.isLoading,
  });

  final Map<String, List<ProfileModel>> groupedMembers;
  final String searchQuery;
  final ValueChanged<String> updateSearchQuery;
  final List<ProfileModel> allUsers;
  final bool isLoading;
}

CircleMembersData useCircleMembers(WidgetRef ref) {
  final searchQuery = useState<String>('');
  final asyncValue = ref.watch(getCircleMembersProvider);
  final currentUserAsync = ref.watch(getCurrentUserProvider);

  // Track if we've loaded data at least once
  final hasLoadedOnce = useState(false);

  // Update hasLoadedOnce when we have data
  useEffect(() {
    if (asyncValue.hasValue) {
      hasLoadedOnce.value = true;
    }
    return null;
  }, [asyncValue.hasValue]);

  // Only show loading on initial load, not on background refreshes
  final isLoading = !hasLoadedOnce.value && asyncValue.isLoading;

  final (groupedMembers, allUsers) = useMemoized(() {
    return asyncValue.when(
      loading: () => (<String, List<ProfileModel>>{}, <ProfileModel>[]),
      error: (_, __) => (<String, List<ProfileModel>>{}, <ProfileModel>[]),
      data: (result) => result.fold((members) {
        final currentUserId = currentUserAsync.whenOrNull(
          data: (userResult) => userResult.fold((user) => user.id, (_) => null),
        );

        final filteredMembers = currentUserId != null
            ? members
                  .where((member) => member.profile.id != currentUserId)
                  .toList()
            : members;

        final allProfiles = filteredMembers
            .map((member) => member.profile)
            .toList();
        final groupedProfiles = _groupAndFilterMembers(
          filteredMembers,
          searchQuery.value,
        );

        return (groupedProfiles, allProfiles);
      }, (_) => (<String, List<ProfileModel>>{}, <ProfileModel>[])),
    );
  }, [asyncValue, searchQuery.value]);

  return CircleMembersData(
    groupedMembers: groupedMembers,
    searchQuery: searchQuery.value,
    updateSearchQuery: (query) => searchQuery.value = query,
    allUsers: allUsers,
    isLoading: isLoading,
  );
}

Map<String, List<ProfileModel>> _groupAndFilterMembers(
  List<ConnectionMemberModel> members,
  String searchQuery,
) {
  final profiles = members.map((member) => member.profile).toList();

  final filteredMembers = searchQuery.isEmpty
      ? profiles
      : profiles.where((profile) {
          final username = profile.username.toLowerCase();
          final query = searchQuery.toLowerCase();

          return username.contains(query);
        }).toList();

  final grouped = <String, List<ProfileModel>>{};

  for (final profile in filteredMembers) {
    final firstLetter = profile.username.substring(0, 1).toUpperCase();
    grouped.putIfAbsent(firstLetter, () => []).add(profile);
  }

  final sortedKeys = grouped.keys.toList()..sort();
  final sortedGrouped = <String, List<ProfileModel>>{};

  for (final key in sortedKeys) {
    final sortedMembers = grouped[key]!
      ..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
    sortedGrouped[key] = sortedMembers;
  }

  return sortedGrouped;
}
