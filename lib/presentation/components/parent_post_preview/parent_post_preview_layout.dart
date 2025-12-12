import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ParentPostPreviewLayout on MainLayout {
  // Thumbnail dimensions
  double get parentPostPreviewThumbnailWidth => 53.0;
  double get parentPostPreviewThumbnailHeight => 39.0;
  double get parentPostPreviewBorderRadius => 4.0;

  // Blur effect (when parent is deleted)
  double get parentPostPreviewBlurSigma => 8.0;
  double get parentPostPreviewBlurOpacity => 0.1;

  // Play icon (for video content)
  double get parentPostPreviewPlayIconSize => 16.0;

  // Spacing
  double get parentPostPreviewThumbnailToUsername => 10.0;
}
