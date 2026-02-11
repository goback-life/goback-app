import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin YourCircleLayout on MainLayout {
  // Friend tile
  double get friendTileHeight => 59.0;
  double get friendTileLeftIndent => 57.0;
  double get friendAvatarSize => 39.0;
  double get friendAvatarToText => 10.0;
  double get friendTextSize => 24.0;
  double get friendLetterSpacing => -1.44;
  double get friendChevronRightPad => 74.0;

  // Bottom bar
  double get bottomBarLeftPadding => 42.0;
  double get bottomBarRightPadding => 24.0;
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
}
