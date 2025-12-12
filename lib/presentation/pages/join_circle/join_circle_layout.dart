import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin JoinCircleLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get rightMargin => 50.0;

  @override
  double get topMargin => 70.0;

  @override
  double get bottomMargin => 10.0;

  @override
  double get horizontalMargin => 50.0;

  @override
  double get rightPadding => 67.0;

  double get borderRadius => 8.0;

  double get mainAppBarToTitle => 40.0;

  double get titleToText => 16.0;

  double get descriptionToFormField => 20.0;

  double get cursorHeight => 22.0;
}
