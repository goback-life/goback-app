import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin CircleProfileLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 60.0;

  @override
  double get verticalSpacing => 20.0;

  @override
  double get horizontalMargin => 100.0;

  @override
  double get horizontalSpacing => 16.0;

  double get titleToImage => 50.0;

  double get buttonToCalendar => 30.0;

  double get phoneToText => 8.0;
}
