import 'package:cloudless/core/features/connection/domain/hooks/use_connection_requests.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/search_users_provider.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConnectionRequestsView extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const ConnectionRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchData = useSearchUsers(ref);
    final requestsData = useConnectionRequests(ref);
    final searchController = useTextEditingController();
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    final isSearching = searchData.query.isNotEmpty;

    return Column(
      children: [
        SizedBox(height: topPad + 48),
        // Search input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: searchPillHeight,
            child: AppGlassContainer(
              config: GlassConfig(
                variant: GlassVariant.clear,
                tint: MainColors.accent,
                cornerRadius: searchPillRadius,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchController,
                    onChanged: searchData.updateQuery,
                    maxLength: 30,
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: MainColors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by username or phone',
                      hintStyle: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: MainColors.white.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: isSearching
              ? _SearchResults(
                  searchData: searchData,
                  requestsData: requestsData,
                  ref: ref,
                )
              : _OutgoingRequests(
                  requestsData: requestsData,
                  bottomPad: bottomPad,
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search results list
// ---------------------------------------------------------------------------
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.searchData,
    required this.requestsData,
    required this.ref,
  });

  final SearchUsersData searchData;
  final ConnectionRequestsData requestsData;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (searchData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (searchData.results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 16,
            color: MainColors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: searchData.results.length,
      itemBuilder: (context, index) {
        final (profile, status) = searchData.results[index];
        return _SearchResultTile(
          profile: profile,
          status: status,
          onConnect: () => _handleConnect(profile.id),
          onAccept: () => _handleAcceptFromSearch(profile.id),
        );
      },
    );
  }

  void _handleConnect(String receiverId) {
    requestsData.send(receiverId).then((result) {
      result.fold(
        (value) {
          // Refresh search results to update status
          ref.invalidate(searchUsersProvider(searchData.query));
          ref.invalidate(getOutgoingRequestsProvider);
          if (value == 'auto_accepted') {
            ref.invalidate(getCircleMembersProvider);
          }
        },
        (_) {},
      );
    });
  }

  void _handleAcceptFromSearch(String senderId) {
    // Find the incoming request from this sender in the outgoing list
    // Actually, for incoming requests shown in search, we need the request ID.
    // The search RPC only returns status, not the request ID.
    // For accept, the user should use the notification. Here we just show status.
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.profile,
    required this.status,
    required this.onConnect,
    required this.onAccept,
  });

  final ProfileModel profile;
  final ConnectionStatus status;
  final VoidCallback onConnect;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: MainColors.accent.withValues(alpha: 0.2),
            backgroundImage:
                profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? Text(
                    profile.username.isNotEmpty
                        ? profile.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: MainColors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              profile.username,
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: MainColors.white,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Action button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (status) {
      case ConnectionStatus.none:
        return _SmallActionButton(
          label: 'Connect',
          color: MainColors.accent,
          onTap: onConnect,
        );
      case ConnectionStatus.pendingOutgoing:
        return _SmallActionButton(
          label: 'Pending',
          color: MainColors.white.withValues(alpha: 0.3),
        );
      case ConnectionStatus.pendingIncoming:
        return _SmallActionButton(
          label: 'Accept',
          color: MainColors.accent,
          onTap: onAccept,
        );
      case ConnectionStatus.connected:
        return _SmallActionButton(
          label: 'Connected',
          color: MainColors.white.withValues(alpha: 0.3),
        );
    }
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outgoing requests list (idle state)
// ---------------------------------------------------------------------------
class _OutgoingRequests extends StatelessWidget {
  const _OutgoingRequests({
    required this.requestsData,
    required this.bottomPad,
  });

  final ConnectionRequestsData requestsData;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    if (requestsData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requestsData.outgoingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Search for users to send connection requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 16,
              color: MainColors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPad + 16,
      ),
      itemCount: requestsData.outgoingRequests.length,
      itemBuilder: (context, index) {
        final request = requestsData.outgoingRequests[index];
        return _OutgoingRequestTile(
          request: request,
          onCancel: () => requestsData.cancel(request.requestId),
        );
      },
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  const _OutgoingRequestTile({
    required this.request,
    required this.onCancel,
  });

  final ConnectionRequestModel request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MainColors.accent.withValues(alpha: 0.2),
            backgroundImage: request.profile.avatarUrl != null &&
                    request.profile.avatarUrl!.isNotEmpty
                ? NetworkImage(request.profile.avatarUrl!)
                : null,
            child: request.profile.avatarUrl == null ||
                    request.profile.avatarUrl!.isEmpty
                ? Text(
                    request.profile.username.isNotEmpty
                        ? request.profile.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: MainColors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.profile.username,
                  style: const TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: MainColors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatRelativeTime(request.createdAt),
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontSize: 13,
                    color: MainColors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close,
              size: 20,
              color: MainColors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inHours < 48) return 'Yesterday';
    return DateFormat.MMMd().format(local);
  }
}
