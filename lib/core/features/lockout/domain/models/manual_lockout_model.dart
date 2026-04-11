class ManualLockoutModel {
  const ManualLockoutModel({
    required this.isLockedOut,
    this.remainingDuration,
    this.isCompletionPending = false,
  });

  final bool isLockedOut;
  final Duration? remainingDuration;

  /// True when lockout timer expired but user hasn't shared/skipped yet.
  /// Used to keep nav overlay blocked on the completion screen.
  final bool isCompletionPending;

  ManualLockoutModel copyWith({
    bool? isLockedOut,
    Duration? remainingDuration,
    bool? isCompletionPending,
  }) {
    return ManualLockoutModel(
      isLockedOut: isLockedOut ?? this.isLockedOut,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      isCompletionPending: isCompletionPending ?? this.isCompletionPending,
    );
  }
}
