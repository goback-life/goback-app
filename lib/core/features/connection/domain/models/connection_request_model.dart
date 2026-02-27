import 'package:cloudless/core/models/profile_model.dart';

enum ConnectionStatus {
  connected,
  pendingOutgoing,
  pendingIncoming,
  none;

  static ConnectionStatus fromString(String value) {
    return switch (value) {
      'connected' => ConnectionStatus.connected,
      'pending_outgoing' => ConnectionStatus.pendingOutgoing,
      'pending_incoming' => ConnectionStatus.pendingIncoming,
      _ => ConnectionStatus.none,
    };
  }
}

class ConnectionRequestModel {
  const ConnectionRequestModel({
    required this.requestId,
    required this.profile,
    required this.createdAt,
    required this.expiresAt,
  });

  final String requestId;
  final ProfileModel profile;
  final DateTime createdAt;
  final DateTime expiresAt;
}
