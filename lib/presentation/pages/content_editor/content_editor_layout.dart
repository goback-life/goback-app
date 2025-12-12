import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ContentEditorLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 60.0;

  @override
  double get verticalSpacing => 32.0;

  @override
  double get bottomMargin => 10;

  double get titleToImage => 20.0;

  double get contentHeight => 20.0;

  double get imageHeight => 278.0;

  double get borderRadius => 4.0;

  double get imageToEdit => 16.0;

  double get mediaToDescription => 30.0;

  double get tagIconSpacing => 4.0;
  double get tagSectionSpacing => 4.0;
  double get tagChipMarginRight => 8.0;
  double get tagChipPaddingHorizontal => 8.0;
  double get tagChipPaddingVertical => 4.0;
  double get searchBarBottomSpacing => 16.0;
  double get userListBottomSpacing => 24.0;
  double get noResultsBottomSpacing => 24.0;
  double get sectionBottomSpacing => 16.0;

  double get userAvatarSize => 32.0;
  double get userAvatarSpacing => 12.0;

  double get topSectionScrollAwayWhenTagging => 500;

  // Video thumbnail preview
  double get thumbnailPreviewWidth => 62.0;
  double get thumbnailPreviewHeight => 47.0;
  double get thumbnailPreviewBottomSpacing => 8.0;
  double get thumbnailPreviewRightSpacing => 8.0;
  double get thumbnailPreviewBorderRadius => 4.0;
}
