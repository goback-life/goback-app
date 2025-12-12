/// Direction for loading calendar posts relative to a reference date.
enum CalendarLoadDirection {
  /// Load posts before (earlier than) the reference date.
  before('before'),

  /// Load posts after (later than) the reference date.
  after('after');

  const CalendarLoadDirection(this.value);

  final String value;
}
