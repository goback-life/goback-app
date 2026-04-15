class ParticipantDistance {
  const ParticipantDistance._();

  static int compute({
    required String participantId,
    required String? joinedVia,
    required Set<String> myFriendIds,
  }) {
    if (myFriendIds.contains(participantId)) return 1;
    if (joinedVia != null && myFriendIds.contains(joinedVia)) return 2;
    return 3;
  }
}
