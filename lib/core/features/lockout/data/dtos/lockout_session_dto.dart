// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_session_dto.freezed.dart';
part 'lockout_session_dto.g.dart';

/// Reads 'lockout_id' (from RPC) or 'id' (from direct query).
Object? _readId(Map<dynamic, dynamic> json, String key) =>
    json['lockout_id'] ?? json['id'];

/// DTO for lockout sessions from the database.
///
/// Represents a server-side lockout session that tracks when users
/// go offline together. Includes location data and participants.
@freezed
sealed class LockoutSessionDto with _$LockoutSessionDto {
  const factory LockoutSessionDto({
    /// Session ID - RPC returns 'lockout_id', direct queries return 'id'
    @JsonKey(readValue: _readId) required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'started_at') required String startedAt,
    @JsonKey(name: 'ends_at') required String endsAt,
    @JsonKey(name: 'action_text') String? actionText,
    @JsonKey(name: 'location_lat') double? locationLat,
    @JsonKey(name: 'location_lng') double? locationLng,
    @JsonKey(name: 'location_name') String? locationName,
    @JsonKey(name: 'venue_tag_id') String? venueTagId,
    @JsonKey(name: 'is_open_ended') @Default(false) bool isOpenEnded,
    @JsonKey(name: 'post_id') String? postId,
    @JsonKey(name: 'created_at') String? createdAt,

    /// Friends who joined this lockout session (UUID array)
    @Default([]) List<String> participants,
    // Denormalized from RPC join:
    String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'joined_via') String? joinedVia,
  }) = _LockoutSessionDto;

  factory LockoutSessionDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutSessionDtoFromJson(json);
}
