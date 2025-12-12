import 'package:cloudless/core/models/profile_model.dart';

class ConnectionMemberModel {
  const ConnectionMemberModel({
    required this.connectionId,
    required this.profile,
  });

  final String connectionId;
  final ProfileModel profile;
}
