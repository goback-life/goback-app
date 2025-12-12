import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_user_chip.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ContentEditorPostTagUserSection extends HookWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorPostTagUserSection({
    required this.taggedUserIds,
    required this.onTaggedUsersChanged,
    required this.allUsers,
    required this.scrollController,
    required this.expandedHeight,
    super.key,
  });

  final List<String> taggedUserIds;
  final ValueChanged<List<String>> onTaggedUsersChanged;
  final List<ProfileModel> allUsers;
  final ScrollController scrollController;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');
    final isSearchExpanded = useState<bool>(false);
    final isHeightExpanded = useState<bool>(false);

    final filteredUsers = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return <ProfileModel>[];
      }

      return allUsers.where((user) {
        final username = user.username.toLowerCase();
        final query = searchQuery.value.toLowerCase();
        final isNotTagged = !taggedUserIds.contains(user.id);

        return username.contains(query) && isNotTagged;
      }).toList();
    }, [searchQuery.value, taggedUserIds, allUsers]);

    void removeUser(String userId) {
      final updatedList = List<String>.from(taggedUserIds)..remove(userId);
      onTaggedUsersChanged(updatedList);

      if (searchQuery.value.isNotEmpty) {
        searchQuery.value = searchController.text;
      }
    }

    void addUser(String userId) {
      final updatedList = List<String>.from(taggedUserIds)..add(userId);
      onTaggedUsersChanged(updatedList);

      searchController.clear();
      searchQuery.value = '';
      isSearchExpanded.value = false;
      FocusScope.of(context).unfocus();
    }

    return SizedBox(
      height: isHeightExpanded.value ? expandedHeight : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Assets.svg.tag.render(),
              SizedBox(width: tagIconSpacing),
              Text(
                translator.translate('pages.content_editor.tag_users'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.scrim,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: tagSectionSpacing),

          if (taggedUserIds.isNotEmpty) ...[
            Wrap(
              children: taggedUserIds.map((userId) {
                final user = allUsers.firstWhere(
                  (u) => u.id == userId,
                  orElse: () =>
                      ProfileModel(id: userId, username: 'Unknown User'),
                );

                return ContentEditorUserChip(
                  username: user.username,
                  onRemove: () => removeUser(userId),
                );
              }).toList(),
            ),
            SizedBox(height: tagSectionSpacing),
          ],

          MainSearchBar(
            onTap: () {
              isHeightExpanded.value = true;
              scrollController.animateTo(
                topSectionScrollAwayWhenTagging,
                duration: Durations.medium2,
                curve: Easing.emphasizedDecelerate,
              );
            },
            onTapOutside: (event) {
              context.unfocus();
              isHeightExpanded.value = false;
            },
            searchQuery: searchQuery.value,
            onSubmitted: (value) {
              searchQuery.value = value;
              isHeightExpanded.value = false;
              context.unfocus();
            },
            onSearchChanged: (value) {
              searchQuery.value = value;
              isSearchExpanded.value = value.isNotEmpty;
            },
          ),

          SizedBox(height: searchBarBottomSpacing),

          if (isSearchExpanded.value && filteredUsers.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = taggedUserIds.contains(user.id);

                return MainMemberItem(
                  member: user,
                  action: MemberItemAction.none,
                  onTap: () {
                    if (isSelected) {
                      removeUser(user.id);
                    } else {
                      addUser(user.id);
                    }
                  },
                );
              },
            ),
            SizedBox(height: userListBottomSpacing),
          ],

          SizedBox(height: sectionBottomSpacing),

          if (isSearchExpanded.value &&
              filteredUsers.isEmpty &&
              searchQuery.value.isNotEmpty) ...[
            Center(
              child: Text(
                translator.translate('components.searchbar.no_results'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: noResultsBottomSpacing),
          ],
        ],
      ),
    );
  }
}
