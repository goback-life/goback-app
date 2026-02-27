/// Defines the type of notification.
enum NotificationType {
  reaction('reaction'),
  tag('tag'),
  comment('comment'),
  lockoutStarted('lockout_started'),
  lockoutJoined('lockout_joined'),
  friendJoined('friend_joined'),
  connectionRequest('connection_request');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid notification type value: $value'),
    );
  }
}

