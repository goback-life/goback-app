class TimeLimitModel {
  const TimeLimitModel({
    required this.minutes,
    required this.isActive,
    required this.usedMinutes,
    required this.lastUsageDate,
  });

  final int minutes;
  final bool isActive;
  final int usedMinutes;
  final DateTime lastUsageDate;

  bool get isLimitReached => usedMinutes >= minutes;

  int get remainingMinutes => (minutes - usedMinutes).clamp(0, minutes);

  TimeLimitModel copyWith({
    int? minutes,
    bool? isActive,
    int? usedMinutes,
    DateTime? lastUsageDate,
  }) {
    return TimeLimitModel(
      minutes: minutes ?? this.minutes,
      isActive: isActive ?? this.isActive,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      lastUsageDate: lastUsageDate ?? this.lastUsageDate,
    );
  }
}
