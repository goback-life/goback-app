import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin NotificationsLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;
  @override
  double get bottomMargin => 24.0;

  @override
  double get topMargin => 66.0;
  double get titleToImage => 12.0;
  @override
  double get verticalSpacing => 16.0;

  // Notification Item
  double get notificationItemHeight => 80.0;
  double get notificationItemPadding => 16.0;
  double get notificationItemBorderRadius => 12.0;
  double get notificationItemSpacing => 12.0;

  // Notification Unread
  double get notificationUnreadBorderWidth => 3.0;

  // Notification Header
  double get notificationHeaderHeight => 60.0;
}
