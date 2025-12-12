/// Defines the reason for reporting a user.
enum UserReportReason {
  harassment('harassment'),

  hateSpeech('hate_speech'),

  inappropriateContent('inappropriate_content'),

  spam('spam'),

  impersonation('impersonation'),

  blocked('blocked'),

  changedMind('changed_mind');

  const UserReportReason(this.value);

  final String value;

  static UserReportReason fromValue(String value) {
    return UserReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => throw ArgumentError('Invalid reason value: $value'),
    );
  }
}
