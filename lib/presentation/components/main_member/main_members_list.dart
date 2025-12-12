import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_member/main_member_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class MainMembersList extends HookConsumerWidget
    with MainLayout, MainMemberLayout {
  const MainMembersList({
    required this.members,
    required this.groupedMembers,
    required this.searchQuery,
    required this.onSearchChanged,
    this.action = MemberItemAction.navigation,
    this.selectedMembers,
    this.onMemberSelectionChanged,
    this.taggedUserIds,
    this.parentPostAuthorId,
    super.key,
  });

  final List<ConnectionMemberModel> members;
  final Map<String, List<ProfileModel>> groupedMembers;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final MemberItemAction action;
  final Set<String>? selectedMembers;
  final ValueChanged<Set<String>>? onMemberSelectionChanged;
  final Set<String>? taggedUserIds;
  final String? parentPostAuthorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        groupedMembers.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(
                  vertical: membersListNoResultsVerticalPadding,
                ),
                child: Center(
                  child: Text(
                    translator.translate('components.searchbar.no_results'),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getTotalItemCount(),
                itemBuilder: (context, index) {
                  final item = _getItemAtIndex(index);

                  if (item is String) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index > 0 ? membersListGroupHeaderTopPadding : 0.0,
                      ),
                      child: Text(
                        item,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  } else if (item is ProfileModel) {
                    final isTaggedUser =
                        taggedUserIds?.contains(item.id) ?? false;
                    final isParentPostAuthor = parentPostAuthorId == item.id;
                    final isDisabled =
                        action == MemberItemAction.selection &&
                        (isTaggedUser || isParentPostAuthor);

                    return MainMemberItem(
                      member: item,
                      action: action,
                      isSelected: action == MemberItemAction.selection
                          ? selectedMembers?.contains(item.id) ?? false
                          : null,
                      onSelectionChanged: action == MemberItemAction.selection
                          ? (selected) =>
                                _handleMemberSelection(item.id, selected)
                          : null,
                      isDisabled: isDisabled,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
      ],
    );
  }

  void _handleMemberSelection(String memberId, bool selected) {
    if (onMemberSelectionChanged != null && selectedMembers != null) {
      final updatedSelection = Set<String>.from(selectedMembers!);
      if (selected) {
        updatedSelection.add(memberId);
      } else {
        updatedSelection.remove(memberId);
      }
      onMemberSelectionChanged!(updatedSelection);
    }
  }

  int _getTotalItemCount() {
    int count = 0;
    for (final entry in groupedMembers.entries) {
      count += 1;
      count += entry.value.length;
    }
    return count;
  }

  Object _getItemAtIndex(int index) {
    int currentIndex = 0;

    for (final entry in groupedMembers.entries) {
      if (currentIndex == index) {
        return entry.key;
      }
      currentIndex++;

      for (final member in entry.value) {
        if (currentIndex == index) {
          return member;
        }
        currentIndex++;
      }
    }

    throw RangeError.index(index, this);
  }
}
