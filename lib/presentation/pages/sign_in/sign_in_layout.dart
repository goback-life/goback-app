import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin SignInLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 70.0;

  @override
  double get bottomMargin => 10.0;

  @override
  double get verticalSpacing => 24.0;

  @override
  double get leftPadding => 12.0;

  @override
  double get topPadding => 6.0;

  double get borderRadius => 8.0;

  double get titleToForm => 24.0;

  double get imageToDescription => 70.0;

  double get privacyToButton => 120.0;

  double get checkBoxToText => 12.0;

  double get checkBoxSize => 16.0;

  double get checkSize => 12.0;

  double get checkBoxBorderRadius => 4.0;
}
