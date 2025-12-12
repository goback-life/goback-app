extension NumRangeMap on num {
  /// extension method to quickly map any value from an expected starting range
  ///  to an expected destination range, with a clamp parameter that defaults to
  ///  true to avoid exceeding the range bounds. for example:
  ///  ```dart
  /// print(7.rangeMap(from:(0,10))); // 0.7
  /// print(7.rangeMap(from:(0,10), to:(100,200))); // 170
  /// print(15.rangeMap(from:(0,10), to:(100,200))); // 200
  /// print(15.rangeMap(from:(0,10), to:(100,200), clamp: false)); // 250
  /// ```
  double rangeMap({
    (double toMin, double toMax) to = (0, 1),
    (double fromMin, double fromMax) from = (0, 1),
    bool clamp = true,
  }) =>
      to.$1 +
      ((this - from.$1) / (from.$2 - from.$1))
              .modalClamp(0.0, 1.0, apply: clamp) *
          (to.$2 - to.$1);
}

extension on num {
  num modalClamp(num lowerLimit, num upperLimit, {required bool apply}) =>
      apply ? clamp(lowerLimit, upperLimit) : this;
}
