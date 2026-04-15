import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin YourCircleLayout on MainLayout {
  // Friend tile
  double get friendTileHeight => 59.0;
  double get friendTileLeftIndent => 16.0;
  double get friendAvatarSize => 39.0;
  double get friendAvatarToText => 10.0;
  double get friendTextSize => 24.0;
  double get friendLetterSpacing => -1.44;
  double get friendChevronRightPad => 16.0;

  // Bottom bar — matches feed page horizontalPadding (16px each side)
  double get bottomBarLeftPadding => 16.0;
  double get bottomBarRightPadding => 16.0;
  double get bottomBarBottomPadding => 16.0;

  // Search pill
  double get searchPillWidth => 231.0;
  double get searchPillHeight => 51.0;
  double get searchPillRadius => 47.0;

  // Add button
  double get addButtonSize => 51.0;

  // Arrow buttons
  double get arrowWidth => 48.0;
  double get arrowHeight => 57.486;
  double get arrowSpacing => 8.0;

  // Swipe
  double get swipeDeleteThreshold => 0.3;

  // Remove mode
  double get removeButtonWidth => 318.0;
  double get removeButtonHeight => 51.0;
  double get checkboxSize => 18.0;
  double get checkboxRadius => 5.0;

  // Leaderboard
  double get kingTileHeight => 66.0;
  double get kingAvatarSize => 42.0;
  double get rankWidth => 28.0;
  double get rankRightMargin => 10.0;
  double get accentBarWidth => 3.0;
  double get accentBarHeight => 28.0;
  double get kingAccentBarHeight => 32.0;
  double get accentBarLeftOffset => 14.0;
}
