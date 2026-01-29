import 'package:cloudless/core/models/profile_model.dart';

class ConnectionMemberModel {
  const ConnectionMemberModel({
    required this.friendshipId,
    required this.profile,
  });

  final String friendshipId;
  final ProfileModel profile;
}
