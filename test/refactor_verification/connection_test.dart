// Connection Feature - Refactor Verification Tests
// Documents current behavior contracts for the connection feature.
// These are compile-time/structural checks, not runtime tests
// (since we cannot run `fvm flutter test` in this environment).

// =============================================================================
// BEHAVIOR CONTRACTS
// =============================================================================
//
// 1. ConnectionService (data/services/connection_service.dart)
//    - Implements ConnectionServiceContract
//    - createInviteCode: generates 6-char alphanumeric code, max 100 active, 72h default expiry, 3 retry attempts on duplicate
//    - validateInviteCode: checks existence, usage, expiry, self-use, circle size limits (150), existing friendship
//    - joinCircle: calls 'join_friendship_transaction' RPC
//    - getCircleMembers: delegates to getCircleMembersBasic + enrichMembersWithAvatars
//    - getCircleMembersBasic: calls 'get_user_friends' RPC, maps to GetCircleMembersResponseDto
//    - enrichMembersWithAvatars: batches of 10, uses signedUrlProvider
//    - removeConnection: orders UUIDs (user_a_id < user_b_id), direct DELETE on friendships
//    - isUserConnected: orders UUIDs, checks friendships table
//    - searchUsers: calls 'search_users' RPC
//    - sendConnectionRequest: calls 'send_connection_request' RPC
//    - respondToConnectionRequest: calls 'respond_to_connection_request' RPC
//    - cancelConnectionRequest: direct DELETE on connection_requests
//    - getOutgoingRequests: calls 'get_outgoing_connection_requests' RPC
//    - getIncomingRequests: calls 'get_incoming_connection_requests' RPC, remaps sender->receiver fields
//    - _orderUserIds: helper for UUID ordering (compareTo < 0)
//    - _generateRandomCode: Random.secure(), 6 chars from A-Z0-9
//
// 2. ConnectionRepository (data/repositories/connection_repository.dart)
//    - Implements ConnectionRepositoryContract
//    - Uses SupabaseResultProcessor mixin
//    - All methods delegate to ConnectionServiceContract + exception mappers
//    - getCircleMembers converts DTOs to ConnectionMemberModel (via inline mapping)
//    - searchUsers/request methods use ConnectionRequestException as fallback
//
// 3. Provider Wiring
//    - connectionServiceProvider: creates ConnectionService with supabase + ref
//    - connectionRepositoryProvider: creates ConnectionRepository with connectionService
//    - getCircleMembersProvider: class-based, progressive loading (basic -> avatar enrichment in background)
//    - createInviteCodeProvider: delegates via CreateInviteCodeUseCase
//    - validateInviteCodeProvider: delegates via ValidateInviteCodeUseCase
//    - joinCircleProvider: delegates via JoinCircleUseCase, invalidates getCircleMembersProvider on success
//    - removeConnectionProvider: delegates via RemoveConnectionUseCase, invalidates getCircleMembersProvider on success
//    - isUserConnectedProvider: directly calls connectionService.isUserConnected
//    - searchUsersProvider: calls connectionService.searchUsers, maps to (ProfileModel, ConnectionStatus)
//    - sendConnectionRequestProvider: directly calls connectionService
//    - respondToConnectionRequestProvider: directly calls connectionService
//    - cancelConnectionRequestProvider: directly calls connectionService
//    - getOutgoingRequestsProvider: maps OutgoingRequestDto -> ConnectionRequestModel
//    - getIncomingRequestsProvider: maps OutgoingRequestDto -> ConnectionRequestModel
//
// 4. Exception Hierarchy
//    - ConnectionException extends MainException (base)
//    - ConnectionDataException extends MainException (data layer base)
//    - Data exceptions: ConnectionAlreadyExistsException, ConnectionNotFoundException,
//      ConnectionUnauthorizedException, GetCircleMembersFailedException,
//      InviteCodeExpiredException (DATA - UNUSED), InviteCodeGenerationException,
//      InviteCodeInvalidException, InviteCodeValidationFailedException,
//      InviteLimitException, RemoveConnectionFailedException
//    - Domain exceptions: CannotUseOwnInviteCodeException, CircleFullException,
//      ConnectionRequestException, InviteCodeAlreadyUsedException,
//      InviteCodeCreationFailedException, InviteCodeExpiredException (DOMAIN - USED),
//      InviteCodeNotFoundException, JoinCircleFailedException,
//      TargetUserCircleSizeLimitException, UserCircleSizeLimitException,
//      UsersAlreadyConnectedException
//
// 5. Dead Code Identified
//    - data/exceptions/invite_code_expired_exception.dart: never imported, duplicates domain version
//    - data/dtos/connection_dto.dart + .freezed.dart + .g.dart: only used by connection_dto_to_model_mapper.dart
//    - data/mappers/connection_dto_to_model_mapper.dart: never used outside its own file
//    - data/dtos/invite_code_dto.dart + .freezed.dart + .g.dart: only used by invite_code_dto_to_model_mapper.dart
//    - data/mappers/invite_code_dto_to_model_mapper.dart: never used outside its own file
//    - data/dtos/profile_dto.dart + .freezed.dart + .g.dart: only used by mappers above (which are dead)
//    - data/mappers/profile_dto_to_model_mapper.dart: only used by the two dead mappers above
//    - domain/models/invite_code_model.dart: only used by dead invite_code_dto_to_model_mapper.dart
//    - domain/use_cases/get_circle_members_use_case.dart: never used (provider uses service directly)
//
// 6. Duplicate Code Identified
//    - SearchUserResult typedef: defined in both search_users_provider.dart and use_search_users.dart
//    - _groupContacts/_groupAndFilterContacts: similar logic in use_contact_with_permission.dart
//      and use_phone_contact.dart (different enough to not merge without risk)
//    - UUID ordering in removeConnection: reimplements _orderUserIds logic inline
//
// 7. Files at or near 500-line limit
//    - connection_service.dart: 479 lines (close but under limit)
//
// =============================================================================
// PUBLIC API SURFACE (must not change)
// =============================================================================
//
// ConnectionServiceContract: 13 methods (createInviteCode, validateInviteCode,
//   joinCircle, getCircleMembersBasic, enrichMembersWithAvatars, getCircleMembers,
//   removeConnection, isUserConnected, searchUsers, sendConnectionRequest,
//   respondToConnectionRequest, cancelConnectionRequest, getOutgoingRequests,
//   getIncomingRequests)
//
// ConnectionRepositoryContract: 10 methods (createInviteCode, validateInviteCode,
//   joinCircle, getCircleMembers, removeConnection, searchUsers,
//   sendConnectionRequest, respondToConnectionRequest, cancelConnectionRequest,
//   getOutgoingRequests, getIncomingRequests)
//
// All providers: same function signatures (generated)
// All hooks: same return types and signatures
// All models: same field signatures
// All exceptions: same class names and hierarchies
