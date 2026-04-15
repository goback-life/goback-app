class ManualLockoutModel {
  const ManualLockoutModel({
    required this.isLockedOut,
    this.remainingDuration,
    this.isCompletionPending = false,
    this.isOpenEnded = false,
    this.venueName,
    this.lockoutStartTime,
  });

  final bool isLockedOut;
  final Duration? remainingDuration;

  /// True when lockout timer expired but user hasn't shared/skipped yet.
  /// Used to keep nav overlay blocked on the completion screen.
  final bool isCompletionPending;

  /// True for venue (NFC tag) lockouts — no fixed end time, count-up timer.
  final bool isOpenEnded;

  /// Venue name for NFC lockouts (e.g. "The Dunvegan").
  final String? venueName;

  /// When the lockout started — used to compute elapsed time for open-ended
  /// lockouts.
  final DateTime? lockoutStartTime;

  ManualLockoutModel copyWith({
    bool? isLockedOut,
    Duration? remainingDuration,
    bool? isCompletionPending,
    bool? isOpenEnded,
    String? venueName,
    DateTime? lockoutStartTime,
  }) {
    return ManualLockoutModel(
      isLockedOut: isLockedOut ?? this.isLockedOut,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      isCompletionPending: isCompletionPending ?? this.isCompletionPending,
      isOpenEnded: isOpenEnded ?? this.isOpenEnded,
      venueName: venueName ?? this.venueName,
      lockoutStartTime: lockoutStartTime ?? this.lockoutStartTime,
    );
  }
}
