import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/main_empty_state.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/components/main_member/main_members_list.dart';
import 'package:cloudless/presentation/components/main_search_bar.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_actions_widget.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/widgets.dart';

class YourCircleView extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const YourCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleMembersData = useCircleMembers(ref);
    final asyncValue = ref.watch(getCircleMembersProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: MainDataLoader(
        provider: asyncValue,
        useScaffold: false,
        onRetry: () {
          ref.invalidate(getCircleMembersProvider);
        },
        builder: (context, members) {
          if (members.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const YourCircleActionsWidget(),
                SizedBox(height: emptyStateActionsToEmpty),
                const MainEmptyState(),
              ],
            );
          }

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(vertical: viewVerticalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const YourCircleActionsWidget(),
                SizedBox(height: withMembersActionsToList),
                MainSearchBar(
                  searchQuery: circleMembersData.searchQuery,
                  onSearchChanged: circleMembersData.updateSearchQuery,
                ),
                SizedBox(height: membersListSearchToList),
                MainMembersList(
                  members: members,
                  groupedMembers: circleMembersData.groupedMembers,
                  searchQuery: circleMembersData.searchQuery,
                  onSearchChanged: circleMembersData.updateSearchQuery,
                  action: MemberItemAction.navigation,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
