import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin MainAlertLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get horizontalMargin => 60.0;

  @override
  double get verticalMargin => 20.0;

  @override
  double get height => 40.0;

  double get borderRadius => 20.0;

  double get titleToContent => 20.0;

  double get contentToAction => 29.0;

  double get spaceBetweenButtons => 13.0;
}
