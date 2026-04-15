import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/dtos/outgoing_request_dto.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Contract for connection service that handles direct database operations
/// and business logic for user connections and invite codes.
///
/// Implementations should handle raw database interactions, generate invite
/// codes, validate them, and manage circle memberships. This service layer
/// throws specific exceptions for various failure scenarios.
abstract class ConnectionServiceContract {
  /// Creates a new invite code that can be shared with other users.
  ///
  /// Generates a unique 6-character alphanumeric code that expires after
  /// the specified hours. The code allows other users to join the creator's
  /// circle through the invite system.
  ///
  /// Params:
  /// - `expiryHours`: Hours until the invite expires (default: 24).
  ///
  /// Returns the generated invite code as a String wrapped in Result.
  ///
  /// Throws various exceptions for duplicate codes, database errors, or
  /// generation failures after retry attempts.
  FutureResult<String> createInviteCode({int expiryHours = 24});

  /// Validates an invite code and returns creator information if valid.
  ///
  /// Performs comprehensive validation including expiry check, usage status,
  /// self-invitation prevention, and existing connection verification.
  /// Returns detailed information about the code creator on success.
  ///
  /// Params:
  /// - `code`: The invite code to validate.
  ///
  /// Returns [InviteValidationResult] containing creator profile data wrapped in Result.
  ///
  /// Throws specific exceptions for:
  /// - Invalid/not found codes
  /// - Expired codes
  /// - Already used codes
  /// - Self-invitation attempts
  /// - Existing connections between users
  FutureResult<InviteValidationResult> validateInviteCode(String code);

  /// Joins the current user to the invite code creator's circle.
  ///
  /// Executes a database transaction that marks the invite as used and
  /// creates bidirectional connection records between users. This operation
  /// should be atomic to prevent partial state issues.
  ///
  /// Params:
  /// - `inviteCode`: Valid invite code to join (should be pre-validated).
  ///
  /// Returns true on successful join operation wrapped in Result.
  ///
  /// Throws connection exceptions for validation failures or database errors
  /// during the transaction.
  FutureResult<bool> joinCircle(String inviteCode);

  /// Retrieves circle members data from database without avatar URLs.
  /// This allows for fast initial data loading while avatar URLs are fetched separately.
  ///
  /// Returns a list of member DTOs with null avatar URLs.
  FutureResult<List<GetCircleMembersResponseDto>> getCircleMembersBasic();

  /// Fetches avatar URLs for a list of members synchronously (preserving original mechanism).
  /// This method fetches URLs one by one in sequence, exactly as before.
  ///
  /// Params:
  /// - `members`: List of member DTOs to enrich with avatar URLs
  ///
  /// Returns a list of member DTOs with avatar URLs populated.
  FutureResult<List<GetCircleMembersResponseDto>> enrichMembersWithAvatars(
    List<GetCircleMembersResponseDto> members,
  );

  /// Retrieves all members connected to the current user's circle.
  ///
  /// Returns raw database records containing connection IDs and profile
  /// information for all users connected to the current user. Results
  /// are ordered by username alphabetically.
  ///
  /// Returns a list of raw database maps with connection and profile data.
  ///
  /// Throws database or network exceptions for query failures.
  FutureResult<List<GetCircleMembersResponseDto>> getCircleMembers();

  /// Removes bidirectional connection between two users
  ///
  /// Executes database function that removes both A→B and B→A connections
  /// atomically to maintain data consistency.
  ///
  /// Params:
  /// - `userId`: ID of the user to remove from current user's circle
  ///
  /// Returns true on successful removal wrapped in Result.
  ///
  /// Throws connection exceptions for database errors or if users
  /// are not connected.
  FutureResult<bool> removeConnection(String userId);

  /// Checks if the current user is connected to the specified user
  ///
  /// Verifies if a bidirectional connection exists between the current
  /// user and the target user ID.
  ///
  /// Params:
  /// - `userId`: ID of the user to check connection with
  ///
  /// Returns true if users are connected, false otherwise wrapped in Result.
  ///
  /// Throws database exceptions for query failures.
  FutureResult<bool> isUserConnected(String userId);

  /// Searches users by username prefix or phone number.
  /// Returns list of maps with user_id, username, avatar_url, connection_status.
  FutureResult<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 10,
  });

  /// Sends a connection request. Returns 'sent' or 'auto_accepted'.
  ///
  /// Optional [contextType] and [contextId] provide context about where
  /// the request originated (e.g. 'lockout' with a lockout session ID).
  FutureResult<String> sendConnectionRequest(
    String receiverId, {
    String? contextType,
    String? contextId,
  });

  /// Responds to a connection request (accept or deny).
  FutureResult<void> respondToConnectionRequest(
    String requestId, {
    required bool accept,
  });

  /// Cancels an outgoing connection request (direct DELETE via RLS).
  FutureResult<void> cancelConnectionRequest(String requestId);

  /// Gets all pending outgoing connection requests.
  FutureResult<List<OutgoingRequestDto>> getOutgoingRequests();

  /// Gets all pending incoming connection requests.
  FutureResult<List<OutgoingRequestDto>> getIncomingRequests();
}
