// extensions to quickly get a duration from a number without having to call the constructor
//  e.g.: [250.milliseconds] instead of [const Duration(milliseconds: 250)]
extension IntToDuration on int {
  Duration get microseconds => Duration(microseconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);
}

// extensions to quickly get a duration from a number without having to call the constructor
//  e.g.: [250.milliseconds] instead of [const Duration(milliseconds: 250)]
extension DoubleToDuration on double {
  Duration get microseconds => Duration(microseconds: round());
  Duration get milliseconds =>
      (this * Duration.microsecondsPerMillisecond).microseconds;
  Duration get seconds => (this * Duration.microsecondsPerSecond).microseconds;
  Duration get minutes => (this * Duration.microsecondsPerMinute).microseconds;
  Duration get hours => (this * Duration.microsecondsPerHour).microseconds;
  Duration get days => (this * Duration.microsecondsPerDay).microseconds;
}
