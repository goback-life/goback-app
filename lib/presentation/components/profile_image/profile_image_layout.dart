import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ProfileImageLayout on MainLayout {
  double get imageSize => 120.0;
  double get iconSize => 24.0;
  double get borderWidth => 2.0;

  double get iconSizeRatio => 0.4;
  double get fallbackFontSizeRatio => 0.4;
  double get fallbackFontSizeRatioLarge => 0.3;
  double get smallImageThreshold => 40.0;

  double get loadingStrokeWidth => 2.0;
  double get loadingOpacity => 0.1;

  double get containerOpacity => 0.1;

  double get placeholderPadding => 20.0;

  @override
  double get horizontalPadding => 20.0;

  @override
  double get verticalSpacing => 20.0;

  @override
  double get horizontalMargin => 100.0;

  double get borderRadius => 12.0;
}
