import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

typedef MemberExclusionResult = ({
  String searchQuery,
  Set<String> selectedMembers,
  Set<String> excludedMembers,
  Set<String> taggedUserIds,
  String? parentPostAuthorId,
  Map<String, List<ProfileModel>> groupedMembers,
  ValueChanged<String> updateSearchQuery,
  ValueChanged<Set<String>> updateSelectedMembers,
  void Function(String memberId, {required bool selected})
  toggleMemberSelection,
  VoidCallback selectAll,
  VoidCallback deselectAll,
  void Function(String memberId) selectOnly,
  void Function(
    List<ConnectionMemberModel> members, {
    List<String>? taggedUsers,
    List<String>? excludedUsers,
    String? parentPostAuthorId,
  })
  initializeWith,
});

MemberExclusionResult useMemberExclusion(WidgetRef ref) {
  final searchQuery = useState<String>('');
  final selectedMembers = useState<Set<String>>({});
  final taggedUserIds = useState<Set<String>>({});
  final parentAuthorIdState = useState<String?>(null);
  final allMembers = useState<List<ConnectionMemberModel>>([]);
  final initialized = useState<bool>(false);

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSelectedMembers(Set<String> members) {
    selectedMembers.value = members;
  }

  void toggleMemberSelection(String memberId, {required bool selected}) {
    if (taggedUserIds.value.contains(memberId) && !selected) {
      return;
    }

    if (parentAuthorIdState.value == memberId && !selected) {
      return;
    }

    final updatedSelection = Set<String>.from(selectedMembers.value);
    if (selected) {
      updatedSelection.add(memberId);
    } else {
      updatedSelection.remove(memberId);
    }
    selectedMembers.value = updatedSelection;
  }

  void selectAll() {
    final allMemberIds = allMembers.value
        .map((member) => member.profile.id)
        .toSet();
    selectedMembers.value = allMemberIds;
  }

  void deselectAll() {
    // Keep tagged users and parent post author selected
    final requiredMembers = <String>{};
    if (taggedUserIds.value.isNotEmpty) {
      requiredMembers.addAll(taggedUserIds.value);
    }
    if (parentAuthorIdState.value != null) {
      requiredMembers.add(parentAuthorIdState.value!);
    }
    selectedMembers.value = requiredMembers;
  }

  void selectOnly(String memberId) {
    // Keep tagged users and parent post author selected
    final requiredMembers = <String>{};
    if (taggedUserIds.value.isNotEmpty) {
      requiredMembers.addAll(taggedUserIds.value);
    }
    if (parentAuthorIdState.value != null) {
      requiredMembers.add(parentAuthorIdState.value!);
    }
    // Add the selected member if it's not already in required members
    if (!requiredMembers.contains(memberId)) {
      requiredMembers.add(memberId);
    }
    selectedMembers.value = requiredMembers;
  }

  void initializeWith(
    List<ConnectionMemberModel> members, {
    List<String>? taggedUsers,
    List<String>? excludedUsers,
    String? parentPostAuthorId,
  }) {
    if (parentPostAuthorId != null) {
      parentAuthorIdState.value = parentPostAuthorId;
    } else {
      parentAuthorIdState.value = null;
    }

    if (initialized.value) {
      return;
    }

    allMembers.value = members;

    if (taggedUsers != null) {
      taggedUserIds.value = taggedUsers.toSet();
    }

    final allMemberIds = members.map((member) => member.profile.id).toSet();

    if (excludedUsers != null && excludedUsers.isNotEmpty) {
      selectedMembers.value = allMemberIds.difference(excludedUsers.toSet());
    } else {
      selectedMembers.value = allMemberIds;
    }

    initialized.value = true;
  }

  final groupedMembers = useMemoized(() {
    final profiles = allMembers.value.map((member) => member.profile).toList();

    final filteredProfiles = searchQuery.value.isEmpty
        ? profiles
        : profiles.where((profile) {
            return profile.username.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
          }).toList();

    final Map<String, List<ProfileModel>> grouped = {};

    for (final profile in filteredProfiles) {
      final firstLetter = profile.username.isNotEmpty
          ? profile.username[0].toUpperCase()
          : '#';

      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(profile);
    }

    final sortedGrouped = Map<String, List<ProfileModel>>.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    for (final entry in sortedGrouped.entries) {
      entry.value.sort((a, b) => a.username.compareTo(b.username));
    }

    return sortedGrouped;
  }, [allMembers.value, searchQuery.value]);

  final excludedMembers = useMemoized(() {
    final allMemberIds = allMembers.value
        .map((member) => member.profile.id)
        .toSet();
    return allMemberIds.difference(selectedMembers.value);
  }, [allMembers.value, selectedMembers.value]);

  return (
    searchQuery: searchQuery.value,
    selectedMembers: selectedMembers.value,
    excludedMembers: excludedMembers,
    taggedUserIds: taggedUserIds.value,
    parentPostAuthorId: parentAuthorIdState.value,
    groupedMembers: groupedMembers,
    updateSearchQuery: updateSearchQuery,
    updateSelectedMembers: updateSelectedMembers,
    toggleMemberSelection: toggleMemberSelection,
    selectAll: selectAll,
    deselectAll: deselectAll,
    selectOnly: selectOnly,
    initializeWith: initializeWith,
  );
}
