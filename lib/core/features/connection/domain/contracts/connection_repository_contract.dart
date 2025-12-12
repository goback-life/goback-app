import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Contract for a connection repository that sits between the
/// service layer and higher-level domain/UI code.
///
/// Implementations should translate service exceptions into domain-specific
/// failures, wrap results in [Result<T>] for consistent error handling,
/// and transform raw data into domain models. This provides a clean
/// abstraction for connection and invite code operations.
abstract class ConnectionRepositoryContract {
  /// Creates a new invite code with comprehensive error handling.
  ///
  /// Wraps the service layer invite code generation with domain-specific
  /// error translation. Network issues, generation failures, and database
  /// errors are mapped to appropriate domain exceptions.
  ///
  /// Params:
  /// - `expiryHours`: Hours until the invite expires (default: 24).
  ///
  /// Returns [Result<String>] containing the invite code on success or
  /// a domain-specific failure with error information.
  Future<Result<String>> createInviteCode({int expiryHours = 24});

  /// Validates an invite code with structured error handling.
  ///
  /// Performs validation through the service layer and translates various
  /// validation failures into domain-appropriate exceptions. Returns
  /// structured validation results for UI consumption.
  ///
  /// Params:
  /// - `code`: The invite code to validate.
  ///
  /// Returns [Result<InviteValidationResult>] with validation outcome.
  /// Success contains creator information, failure contains specific
  /// error details for expired, used, invalid, or self-invitation attempts.
  Future<Result<InviteValidationResult>> validateInviteCode(String code);

  /// Joins the current user to a circle with error translation.
  ///
  /// Executes the join operation through the service layer and handles
  /// various failure scenarios including network issues, validation errors,
  /// and transaction failures with appropriate domain exception mapping.
  ///
  /// Params:
  /// - `inviteCode`: Valid invite code to join.
  ///
  /// Returns [Result<bool>] indicating success or failure with domain-specific
  /// error information for troubleshooting and user feedback.
  Future<Result<bool>> joinCircle(String inviteCode);

  /// Retrieves circle members as domain models with error handling.
  ///
  /// Fetches raw member data through the service layer and transforms it
  /// into [ConnectionMemberModel] domain objects. Handles network failures,
  /// database errors, and data transformation issues gracefully.
  ///
  /// Returns [Result<List<ConnectionMemberModel>>] containing the list of
  /// connected users as domain models, or failure with error details.
  /// The list is ordered alphabetically by username for consistent UI display.
  Future<Result<List<ConnectionMemberModel>>> getCircleMembers();

  /// Removes a user from the current user's circle with error handling.
  ///
  /// Executes bidirectional connection removal through the service layer
  /// and handles various failure scenarios including network issues,
  /// database errors, and validation failures with appropriate domain
  /// exception mapping.
  ///
  /// Params:
  /// - `userId`: ID of the user to remove from circle
  ///
  /// Returns [Result<bool>] indicating success or failure with domain-specific
  /// error information for troubleshooting and user feedback.
  Future<Result<bool>> removeConnection(String userId);
}
