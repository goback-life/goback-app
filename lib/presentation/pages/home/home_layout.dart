import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin HomeLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;
  @override
  double get bottomMargin => 24.0;

  double get createContentButtonSize => 60.0;

  double get feedPostImageBorderRadius => 12.0;

  // Feed Post Card
  double get feedPostTopPadding => 55.0;
  double get feedPostWidth => 250.0;
  double get feedPostHeight => 250.0;
  double get feedPostImageRadius => 6.0;
  double get feedPostOtherUserMarginLeft => 16.0;
  double get feedPostCurrentUserMarginRight => 16.0;

  // Feed Posts List
  double get feedPostsListBottomPadding => 135.0; // Increased to account for bottom buttons (60px height + 84px position + 36px spacing)
  double get feedPostsListScrollTrigger => 200.0;

  // Date Badge
  double get dateBadgeTopPadding => 18.0;
  double get dateBadgeHorizontalPadding => 8.0;
  double get dateBadgeVerticalPadding => 2.0;
  double get dateBadgeBorderRadius => 20.0;

  // Navigation Bar
  double get navBarHeight => 60.0;
  double get logoWidth => 120.0;
  double get logoHeight => 32.0;
  double get navProfileImageSize => 24.0;
  double get navCircleButtonSize => 24.0;
  double get navCircleButtonBorderWidth => 1.5;
  double get navCircleIconSize => 16.0;
  double get navButtonSpacing => 12.0;

  // Scroll Indicator
  double get scrollIndicatorSize => 32.0;
  double get scrollIndicatorMarginRight => 16.0;

  // New Posts Banner
  double get newPostsBannerSize => 21.0;
  double get newPostsBannerMarginRight => 42;

  @override
  double get topMargin => 66.0;
  double get titleToImage => 12.0;
  @override
  double get verticalSpacing => 16.0;

  double get actionsContainerVerticalPadding => 20.0;
  double get actionsContainerHorizontalPadding => 16.0;
  double get actionsContainerBorderRadius => 12.0;
  double get actionsTitleToDescription => 12.0;
  double get actionsDescriptionToButtons => 35.0;
  double get actionsBetweenButtons => 13.0;
}
