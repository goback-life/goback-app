import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin MainErrorLayout on MainLayout {
  double get titleDescriptionSpacing => 80;

  @override
  double get topMargin => 100;

  @override
  double get bottomMargin => 10;

  double get imageToDescription => 55;
}
