import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin PostDetailLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get bottomMargin => 24.0;

  @override
  double get topMargin => 66.0;

  @override
  double get verticalSpacing => 16.0;

  double get iconSize => 24.0;

  // Header dimensions
  double get headerAvatarSize => 24.0;
  double get headerImageToUser => 10.0;
  double get headerTimeToClose => 8.0;
  double get headerIconSize => 16.0;

  // Image dimensions
  double get imageMinHeight => 300.0;
  double get imageMaxHeight => 500.0;
  double get imageHeightRatio => 0.4;
  double get imageRadius => 4.0;

  // Tags section
  double get tagIconSize => 16.0;
  double get tagSpacing => 8.0;

  // Description
  double get descriptionMaxLines => 3.0;
  double get descriptionTruncatorWidth => 24.0;
  double get descriptionTruncatorHeight => 3.0;
  double get descriptionTruncatorRadius => 2.0;
  double get descriptionTruncatorSpacing => 4.0;

  // Reactions
  double get reactionHorizontalPadding => 8.0;
  double get reactionVerticalPadding => 4.0;
  double get reactionIconSize => 12.0;
  double get reactionIconSpacing => 4.0;
  double get reactionSpacing => 8.0;
  double get reactionBorderRadius => 999.0;

  // Reaction Picker Modal
  double get reactionPickerVerticalPadding => 20.0;
  double get reactionPickerHandleWidth => 43.0;
  double get reactionPickerHandleHeight => 4.0;
  double get reactionPickerHandleRadius => 2.0;
  double get reactionPickerHandleToEmojis => 24.0;
  double get reactionPickerEmojiSpacing => 16.0;
  double get reactionPickerEmojiPadding => 12.0;
  double get reactionPickerEmojiRadius => 8.0;
  double get reactionPickerEmojiFontSize => 32.0;
  double get reactionPickerBorderRadius => 12.0;
  double get reactionPickerBorderWidth => 2.0;
  double get reactionPickerBottomSpacing => 33.0;

  // Reactions List Modal
  double get reactionsListMaxHeightRatio => 0.7;
  double get reactionsListTopPadding => 14.0;
  double get reactionsListHandleWidth => 50.0;
  double get reactionsListHandleHeight => 5.0;
  double get reactionsListHandleRadius => 100.0;
  double get reactionsListHandleToContent => 36.0;
  double get reactionsListHorizontalPadding => 16.0;
  double get reactionsListBottomPadding => 38.0;
  double get reactionsListBorderRadius => 12.0;

  // Actions
  double get iconPadding => 8.0;
  double get iconHeight => 24.0;
  double get iconWidth => 32.0;

  // Menu
  double get menuVerticalSpacing => 8.0;
  double get menuBorderRadius => 8.0;
  double get menuBorderWidth => 0.5;
  double get menuIconSize => 20.0;
  double get menuIconSpacing => 10.0;
  double get menuItemHorizontalPadding => 32.0;
  double get menuItemVerticalPadding => 10.0;
  double get menuDividerHeight => 0.5;
  double get menuShadowBlur => 4.0;
  double get menuShadowOpacity => 0.25;
  double get menuShadowOffsetY => 4.0;

  // Report modal
  double get modalHorizontalPadding => 16.0;
  double get modalVerticalPadding => 20.0;
  double get modalHorizontalMargin => 48.0;
  double get modalTitleToDescription => 20.0;
  double get modalDescriptionToActions => 24.0;
  double get modalActionSpacing => 12.0;
  double get modalBorderRadius => 20.0;
  double get modalButtonHeight => 40.0;

  // Spacing
  double get sectionSpacing => 12.0;
  double get actionSpacing => 6.0;

  // Sheet positioning
  double get sheetTopPosition => 150.0;
  double get sheetBottomPosition => 20.0;
  double get sheetHorizontalPosition => 12.0;
  double get sheetBottomMenuPosition => 12.0;

  // View styling
  double get viewPadding => 12.0;
  double get viewBorderRadius => 12.0;

  // Arrow icon
  double get arrowIconSize => 16.0;

  // Parent preview
  double get parentPreviewSpacing => 12.0;
  double get parentPreviewBorderRadius => 4.0;
  double get parentPreviewThumbnailWidth => 53.0;
  double get parentPreviewThumbnailHeight => 39.0;
  double get parentPreviewBlurSigma => 8.0;
  double get parentPreviewBlurOpacity => 0.1;
  double get parentPreviewPlayIconSize => 16.0;

  // Navigation header
  double get navigationHeaderArrowSize => 34.0;
  double get navigationHeaderIconSize => 24.0;

  // Post detail page
  double get postDetailPageBorderRadius => 12.0;
  double get postDetailPageTopOffset => 80.0;
  double get postDetailPageBottomOffset => 30.0;
  double get postDetailPageHeaderSpacing => 20.0;
}
