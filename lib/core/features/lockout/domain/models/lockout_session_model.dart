import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_session_model.freezed.dart';
part 'lockout_session_model.g.dart';

/// Domain model representing a server-side lockout session.
///
/// Tracks when users go offline together, with optional location sharing.
@freezed
sealed class LockoutSessionModel with _$LockoutSessionModel {
  const factory LockoutSessionModel({
    required String id,
    required String userId,
    required DateTime startedAt,
    required DateTime endsAt,
    String? actionText,
    double? locationLat,
    double? locationLng,
    String? locationName,
    String? postId,
    DateTime? createdAt,
    /// Friends who joined this lockout session (user IDs)
    @Default([]) List<String> participants,
    // Denormalized from RPC for display:
    String? username,
    String? avatarUrl,
  }) = _LockoutSessionModel;

  factory LockoutSessionModel.fromJson(Map<String, dynamic> json) =>
      _$LockoutSessionModelFromJson(json);
}
