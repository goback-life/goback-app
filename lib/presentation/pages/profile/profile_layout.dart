import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ProfileLayout on MainLayout {
  // Design reference width from Figma (402px frame).
  double get designWidth => 402.0;

  // Avatar
  double get avatarSize => 132.0;
  double get avatarTopOffset => 55.0;

  // Username
  double get usernameFontSize => 40.0;
  double get usernameTracking => -2.4; // -6% of 40
  double get usernameTopGap => 11.0;

  // Bio
  double get bioFontSize => 24.0;
  double get bioTracking => -1.44; // -6% of 24
  double get bioTopGap => 11.0;
  double get bioMaxWidth => 288.0;

  // Calendar grid
  double get dayCellWidth => 39.0;
  double get dayCellHeight => 48.0;
  double get calendarGridTop => 360.0;
  double get calendarGridWidth => 340.0;
  double get calendarRowSpacing => 59.0;
  double get dayFontSize => 24.0;
  double get dayTracking => -1.44; // -6% of 24
  double get dayCellRadius => 10.0;

  // Month navigation
  double get monthFontSize => 40.0;
  double get monthTracking => -2.4;
  double get monthNavTop => 714.0;
  double get arrowWidth => 41.0;
  double get arrowHeight => 34.0;

  // Hamburger menu
  double get hamburgerBarWidth => 31.0;
  double get hamburgerBarHeight => 5.0;
  double get hamburgerBarRadius => 47.0;
  double get hamburgerBarSpacing => 4.0;
  double get hamburgerTopOffset => 55.0;
  double get hamburgerRightOffset => 20.0;
}
