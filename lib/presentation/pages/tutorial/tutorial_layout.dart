/// Layout constants for the tutorial page.
///
/// Reuses [FeedLayout] for post sizing; defines tutorial-specific values here.
mixin TutorialLayout {
  static const double _ref = 402.0;

  static double scale(double value, double screenWidth) =>
      value * (screenWidth / _ref);

  // -- Tooltip --
  static const double tooltipHPadding = 32.0;
  static const double tooltipCornerRadius = 24.0;

  // -- Lockout phase --
  static const double friendAdderTopFraction = 0.45;
  static const double progressDotSize = 10.0;
  static const double progressDotSpacing = 8.0;
}
