import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin MainMemberLayout on MainLayout {
  double get memberItemVerticalPadding => 12.0;
  double get memberItemImageSize => 32.0;
  double get memberItemImageToText => 10.0;
  double get memberItemIconSize => 24.0;
  double get memberItemBorderRadius => 2.0;

  double get membersListSearchToList => 32.0;
  double get membersListNoResultsVerticalPadding => 48.0;
  double get membersListGroupHeaderTopPadding => 16.0;
}
