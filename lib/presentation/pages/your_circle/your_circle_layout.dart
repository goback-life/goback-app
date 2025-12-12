import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin YourCircleLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 56.0;

  double get titleToImage => 20.0;

  double get actionsContainerVerticalPadding => 20.0;
  double get actionsContainerHorizontalPadding => 16.0;
  double get actionsContainerOpacity => 0.1;
  double get actionsContainerBorderRadius => 20.0;
  double get actionsTitleToDescription => 20.0;
  double get actionsDescriptionToButtons => 36.0;
  double get actionsBetweenButtons => 13.0;

  double get memberItemVerticalPadding => 12.0;
  double get memberItemImageSize => 32.0;
  double get memberItemImageToText => 10.0;

  double get membersListSearchToList => 32.0;
  double get membersListNoResultsVerticalPadding => 48.0;
  double get membersListGroupHeaderTopPadding => 16.0;

  double get viewVerticalPadding => 20.0;
  double get viewMinHeightOffset => 220.0;
  double get viewMinHeightOffsetWithMembers => 240.0;
  double get emptyStateActionsToEmpty => 48.0;
  double get withMembersActionsToList => 24.0;
}
