import 'package:freezed_annotation/freezed_annotation.dart';

part 'outgoing_request_dto.freezed.dart';
part 'outgoing_request_dto.g.dart';

@freezed
sealed class OutgoingRequestDto with _$OutgoingRequestDto {
  const factory OutgoingRequestDto({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'receiver_id') required String receiverId,
    @JsonKey(name: 'receiver_username') required String receiverUsername,
    @JsonKey(name: 'receiver_avatar_url') String? receiverAvatarUrl,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'expires_at') required String expiresAt,
  }) = _OutgoingRequestDto;

  factory OutgoingRequestDto.fromJson(Map<String, dynamic> json) =>
      _$OutgoingRequestDtoFromJson(json);
}
