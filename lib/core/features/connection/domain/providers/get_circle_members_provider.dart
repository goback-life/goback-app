import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
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
    return await basicResult.asyncFold(
      (basicMembers) async {
        // Convert and emit data with placeholders (allows UI to render immediately)
        final placeholderModels = _convertToConnectionMembers(basicMembers);
        state = AsyncValue.data(Result.success(placeholderModels));

        // Then fetch all avatar URLs synchronously (preserving original mechanism)
        final enrichedResult = await service.enrichMembersWithAvatars(basicMembers);
        final completeMembers = enrichedResult.fold(
          (members) => members,
          (error) => basicMembers, // Fall back to basic members if enrichment fails
        );

        // Convert and emit complete data with all avatar URLs
        final completeModels = _convertToConnectionMembers(completeMembers);
        state = AsyncValue.data(Result.success(completeModels));

        return Result.success(completeModels);
      },
      (error) async => Result.failure(error),
    );
  }

  List<ConnectionMemberModel> _convertToConnectionMembers(
    List<GetCircleMembersResponseDto> dtos,
  ) {
    return dtos.map((dto) {
      return ConnectionMemberModel(
        connectionId: dto.connectionId,
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
