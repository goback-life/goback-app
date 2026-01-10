/// Defines the type of notification.
enum NotificationType {
  reaction('reaction'),
  tag('tag'),
  reply('reply'),
  circleJoin('circle_join');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid notification type value: $value'),
    );
  }
}

