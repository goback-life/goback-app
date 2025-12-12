/// Defines the reason for reporting a post.
enum PostReportReason {
  nudity('nudity'),

  shockingContent('shocking_content'),

  hateSpeech('hate_speech'),

  bullying('bullying'),

  spam('spam'),

  changedMind('changed_mind');

  const PostReportReason(this.value);

  final String value;

  static PostReportReason fromValue(String value) {
    return PostReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => throw ArgumentError('Invalid reason value: $value'),
    );
  }
}
