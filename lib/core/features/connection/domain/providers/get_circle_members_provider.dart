import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_service_contract.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_circle_members_provider.g.dart';

/// Fetches the list of circle members with progressive loading.
///
/// This provider emits data in two stages:
/// 1. First emits members with null avatar URLs for immediate UI display (placeholders)
/// 2. Then fetches all avatar URLs synchronously (preserving original mechanism)
/// 3. Finally emits complete data with all avatar URLs
///
/// This provider auto-disposes when no longer watched.
/// For real-time updates, consumers should invalidate this provider
/// or use polling in the UI layer.
@Riverpod(keepAlive: false)
class GetCircleMembers extends _$GetCircleMembers {
  @override
  Future<Result<List<ConnectionMemberModel>>> build() async {
    final service = ref.watch(connectionServiceProvider);

    // First, get basic member data (fast, without avatar URLs)
    final basicResult = await service.getCircleMembersBasic();

    // Handle errors - if basic fetch fails, return error
    return basicResult.fold(
      (basicMembers) {
        // Convert to models with placeholder avatars (from DB cache if available)
        final placeholderModels = _convertToConnectionMembers(basicMembers);

        // Start avatar enrichment in background - don't await!
        // This allows the UI to render immediately with placeholders
        _enrichAvatarsInBackground(service, basicMembers);

        return Result.success(placeholderModels);
      },
      (error) => Result.failure(error),
    );
  }

  /// Enriches avatars in the background without blocking the provider.
  /// Updates state when complete.
  Future<void> _enrichAvatarsInBackground(
    ConnectionServiceContract service,
    List<GetCircleMembersResponseDto> basicMembers,
  ) async {
    try {
      final enrichedResult = await service.enrichMembersWithAvatars(basicMembers);
      final completeMembers = enrichedResult.fold(
        (members) => members,
        (error) => basicMembers, // Fall back to basic members if enrichment fails
      );

      // Update state with complete data (avatars loaded)
      final completeModels = _convertToConnectionMembers(completeMembers);
      state = AsyncValue.data(Result.success(completeModels));
    } catch (e) {
      // Keep placeholder data on error - don't update state
    }
  }

  List<ConnectionMemberModel> _convertToConnectionMembers(
    List<GetCircleMembersResponseDto> dtos,
  ) {
    return dtos.map((dto) {
      return ConnectionMemberModel(
        friendshipId: dto.friendshipId,
        profile: ProfileModel(
          id: dto.id,
          username: dto.username,
          biography: dto.biography,
          avatarUrl: dto.avatarUrl,
          phoneNumber: dto.phoneNumber,
        ),
      );
    }).toList();
  }
}
