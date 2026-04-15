class LockoutParticipantModel {
  const LockoutParticipantModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.joinedVia,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String? joinedVia;
}
