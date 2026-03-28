import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_search_field.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Username search tab for the tutorial friend adder.
class TutorialSearchTab extends HookConsumerWidget {
  const TutorialSearchTab({required this.onFriendAdded, super.key});

  final VoidCallback onFriendAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = useSearchUsers(ref);
    final sendingIds = useState<Set<String>>({});

    Future<void> addFriend(String userId) async {
      if (sendingIds.value.contains(userId)) return;
      sendingIds.value = {...sendingIds.value, userId};

      final result = await ref.read(
        sendConnectionRequestProvider(userId).future,
      );
      result.fold(
        (_) => onFriendAdded(),
        (_) {},
      );

      sendingIds.value = {...sendingIds.value}..remove(userId);
    }

    return Column(
      children: [
        TutorialSearchField(
          hintText: 'Search by username',
          onChanged: search.updateQuery,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: search.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: MainColors.accent),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: search.results.length,
                  itemBuilder: (context, index) {
                    final (profile, status) = search.results[index];
                    final isSending =
                        sendingIds.value.contains(profile.id);
                    final isAlreadyConnected =
                        status == ConnectionStatus.connected;
                    final isPending =
                        status == ConnectionStatus.pendingOutgoing;

                    return _SearchResultRow(
                      username: profile.username,
                      isAlreadyConnected: isAlreadyConnected,
                      isPending: isPending,
                      isSending: isSending,
                      onAdd: () => addFriend(profile.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.username,
    required this.isAlreadyConnected,
    required this.isPending,
    required this.isSending,
    required this.onAdd,
  });

  final String username;
  final bool isAlreadyConnected;
  final bool isPending;
  final bool isSending;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: MainColors.grey300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MainColors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontSize: 14,
                color: MainColors.dark,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isAlreadyConnected)
            const Text(
              'Connected',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontSize: 12,
                color: MainColors.grey500,
                decoration: TextDecoration.none,
              ),
            )
          else if (isPending)
            const Text(
              'Pending',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontSize: 12,
                color: MainColors.grey500,
                decoration: TextDecoration.none,
              ),
            )
          else
            GestureDetector(
              onTap: isSending ? null : onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MainColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MainColors.white,
                        ),
                      )
                    : const Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MainColors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
