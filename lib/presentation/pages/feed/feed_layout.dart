/// Layout constants for the V1 feed page.
///
/// All values are defined at Figma reference width of 402px
/// and must be scaled via [scale] at runtime.
mixin FeedLayout {
  // -- Figma reference --
  static const double _ref = 402.0;

  /// Scale a value from Figma 402px to the actual screen width.
  static double scale(double value, double screenWidth) =>
      value * (screenWidth / _ref);

  // -- Squircle post --
  static const double squircleSize = 250.0;

  // -- Horizontal positioning --
  static const double leftPostInset = 20.0;
  static const double rightPostInsetFromRight = 21.0;

  // -- Avatar / author row --
  static const double avatarSize = 39.0;
  static const double avatarInsetFromSquircle = 15.0;
  static const double avatarToNameGap = 10.0;
  static const double nameTrailingMargin = 15.0;

  // -- Vertical spacing --
  static const double squircleToAuthorGap = 15.0;
  static const double authorToNextPostGap = 30.0;

  // -- Typography at Figma scale --
  static const double usernameFontSize = 21.5;
  static const double usernameLetterSpacing = -1.29; // -6% of fontSize
  static const double dateFontSize = 15.0;

  // -- Lockout button --
  static const double lockoutBottomDistance = 96.0;
  static const double lockoutCenterOffsetX = -6.0;

  // -- Date overlay --
  static const double dateOverlayCornerRadius = 24.0;
  static const double dateOverlayHPadding = 14.0;
  static const double dateOverlayVPadding = 5.0;

  // -- Circle hub button --
  static const double circleHubButtonSize = 32.0;
  static const double circleHubButtonRight = 16.0;

  // -- New posts banner --
  static const double bannerWidth = 102.0;
  static const double bannerHeight = 30.0;
  static const double bannerCornerRadius = 30.0;
  static const double bannerIconSize = 19.0;
  static const double bannerAboveLockout = 16.0;

  // -- Feed list --
  static const double feedBottomPadding = 160.0;
  static const double scrollTriggerDistance = 200.0;

  /// Max width available for the display name text.
  static double nameMaxWidth(double screenWidth) {
    final s = screenWidth / _ref;
    return (squircleSize -
            avatarInsetFromSquircle -
            avatarSize -
            avatarToNameGap -
            nameTrailingMargin) *
        s;
  }
}
