class ManualLockoutModel {
  const ManualLockoutModel({
    required this.isLockedOut,
    this.remainingDuration,
  });

  final bool isLockedOut;
  final Duration? remainingDuration;

  ManualLockoutModel copyWith({
    bool? isLockedOut,
    Duration? remainingDuration,
  }) {
    return ManualLockoutModel(
      isLockedOut: isLockedOut ?? this.isLockedOut,
      remainingDuration: remainingDuration ?? this.remainingDuration,
    );
  }
}

