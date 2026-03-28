import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin PublishContentLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 60.0;

  @override
  double get verticalPadding => 20.0;

  @override
  double get bottomMargin => 10;

  double get titleToImage => 20.0;

  double get membersListSearchToList => 32.0;
}
