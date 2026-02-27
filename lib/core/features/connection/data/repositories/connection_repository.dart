import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/dtos/outgoing_request_dto.dart';
import 'package:cloudless/core/features/connection/data/mappers/create_invite_code_exceptions_mapper.dart';
import 'package:cloudless/core/features/connection/data/mappers/get_circle_members_exceptions_mapper.dart';
import 'package:cloudless/core/features/connection/data/mappers/join_circle_exceptions_mapper.dart';
import 'package:cloudless/core/features/connection/data/mappers/remove_connection_exceptions_mapper.dart';
import 'package:cloudless/core/features/connection/data/mappers/validate_invite_code_exceptions_mapper.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_service_contract.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/connection_request_exception.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:cloudless/core/features/supabase/data/mixins/supabase_result_processor.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ConnectionRepository
    with SupabaseResultProcessor
    implements ConnectionRepositoryContract {
  ConnectionRepository({required this.connectionService});

  final ConnectionServiceContract connectionService;

  @override
  FutureResult<String> createInviteCode({int expiryHours = 72}) async {
    return processSupabaseResult<String, String>(
      request: () =>
          connectionService.createInviteCode(expiryHours: expiryHours),
      responseMapper: (code) async => code,
      exceptionMapper: CreateInviteCodeExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<InviteValidationResult> validateInviteCode(String code) async {
    return processSupabaseResult<
      InviteValidationResult,
      InviteValidationResult
    >(
      request: () => connectionService.validateInviteCode(code),
      responseMapper: (result) async => result,
      exceptionMapper: ValidateInviteCodeExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<bool> joinCircle(String inviteCode) async {
    return processSupabaseResult<bool, bool>(
      request: () => connectionService.joinCircle(inviteCode),
      responseMapper: (success) async => success,
      exceptionMapper: JoinCircleExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<List<ConnectionMemberModel>> getCircleMembers() async {
    return processSupabaseResult<
      List<GetCircleMembersResponseDto>,
      List<ConnectionMemberModel>
    >(
      request: () => connectionService.getCircleMembers(),
      responseMapper: (membersDtos) async {
        return membersDtos.map((dto) {
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
      },
      exceptionMapper: GetCircleMembersExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<bool> removeConnection(String userId) async {
    return processSupabaseResult<bool, bool>(
      request: () => connectionService.removeConnection(userId),
      responseMapper: (success) async => success,
      exceptionMapper: RemoveConnectionExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    return processSupabaseResult<
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>
    >(
      request: () => connectionService.searchUsers(query, limit: limit),
      responseMapper: (results) async => results,
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }

  @override
  FutureResult<String> sendConnectionRequest(String receiverId) async {
    return processSupabaseResult<String, String>(
      request: () => connectionService.sendConnectionRequest(receiverId),
      responseMapper: (result) async => result,
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }

  @override
  FutureResult<void> respondToConnectionRequest(
    String requestId, {
    required bool accept,
  }) async {
    return processSupabaseResult<void, void>(
      request: () => connectionService.respondToConnectionRequest(
        requestId,
        accept: accept,
      ),
      responseMapper: (_) async {},
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }

  @override
  FutureResult<void> cancelConnectionRequest(String requestId) async {
    return processSupabaseResult<void, void>(
      request: () => connectionService.cancelConnectionRequest(requestId),
      responseMapper: (_) async {},
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }

  @override
  FutureResult<List<OutgoingRequestDto>> getOutgoingRequests() async {
    return processSupabaseResult<
      List<OutgoingRequestDto>,
      List<OutgoingRequestDto>
    >(
      request: () => connectionService.getOutgoingRequests(),
      responseMapper: (results) async => results,
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }

  @override
  FutureResult<List<OutgoingRequestDto>> getIncomingRequests() async {
    return processSupabaseResult<
      List<OutgoingRequestDto>,
      List<OutgoingRequestDto>
    >(
      request: () => connectionService.getIncomingRequests(),
      responseMapper: (results) async => results,
      exceptionMapper: (e) => ConnectionRequestException(e.toString()),
    );
  }
}
