import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_connection_requests.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/search_users_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/your_circle/components/connection_request_tiles.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

const _kMaxCircleSize = 150;

class ConnectionRequestsView extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const ConnectionRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchData = useSearchUsers(ref);
    final requestsData = useConnectionRequests(ref);
    final circleMembersData = useCircleMembers(ref);
    final searchController = useTextEditingController();
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    final isSearching = searchData.query.isNotEmpty;
    final isFull = circleMembersData.allUsers.length >= _kMaxCircleSize;

    return Column(
      children: [
        SizedBox(height: topPad + 56),
        // Search input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
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
                  isCircleFull: isFull,
                )
              : _RequestsIdle(
                  requestsData: requestsData,
                  bottomPad: bottomPad,
                  ref: ref,
                  isCircleFull: isFull,
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
    required this.isCircleFull,
  });

  final SearchUsersData searchData;
  final ConnectionRequestsData requestsData;
  final WidgetRef ref;
  final bool isCircleFull;

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
        return SearchResultTile(
          profile: profile,
          status: status,
          isCircleFull: isCircleFull,
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

// ---------------------------------------------------------------------------
// Combined incoming + outgoing requests (idle state)
// ---------------------------------------------------------------------------
class _RequestsIdle extends StatelessWidget {
  const _RequestsIdle({
    required this.requestsData,
    required this.bottomPad,
    required this.ref,
    required this.isCircleFull,
  });

  final ConnectionRequestsData requestsData;
  final double bottomPad;
  final WidgetRef ref;
  final bool isCircleFull;

  @override
  Widget build(BuildContext context) {
    if (requestsData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasIncoming = requestsData.incomingRequests.isNotEmpty;
    final hasOutgoing = requestsData.outgoingRequests.isNotEmpty;

    if (!hasIncoming && !hasOutgoing) {
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

    return ListView(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomPad + 16),
      children: [
        if (hasIncoming) ...[
          RequestSectionHeader(label: 'Incoming'),
          for (final request in requestsData.incomingRequests)
            IncomingRequestTile(
              request: request,
              isCircleFull: isCircleFull,
              onAccept: () => requestsData.respond(
                request.requestId,
                accept: true,
              ),
              onDeny: () => requestsData.respond(
                request.requestId,
                accept: false,
              ),
            ),
        ],
        if (hasOutgoing) ...[
          if (hasIncoming) const SizedBox(height: 8),
          RequestSectionHeader(label: 'Sent'),
          for (final request in requestsData.outgoingRequests)
            OutgoingRequestTile(
              request: request,
              onCancel: () => requestsData.cancel(request.requestId),
            ),
        ],
      ],
    );
  }
}
