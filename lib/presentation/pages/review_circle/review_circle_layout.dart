import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ReviewCircleLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 56.0;

  double get titleToImage => 20.0;

  double get viewVerticalPadding => 20.0;
  double get membersListSearchToList => 32.0;
  double get membersListNoResultsVerticalPadding => 48.0;
  double get membersListGroupHeaderTopPadding => 16.0;

  double get bottomButtonPadding => 16.0;
  double get bottomButtonToContent => 24.0;
}

