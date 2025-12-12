import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin InviteToCircleLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get topMargin => 60.0;

  @override
  double get verticalSpacing => 24.0;

  @override
  double get horizontalMargin => 17.0;

  @override
  double get horizontalSpacing => 16.0;

  @override
  double get verticalPadding => 12.0;

  double get titleToImage => 12.0;

  double get buttonToCalendar => 30.0;

  @override
  double get verticalMargin => 8.0;

  double get groupHeaderTopPadding => 24.0;
  double get groupHeaderBottomPadding => 8.0;
  double get searchBarBottomSpacing => 16.0;
  double get permissionIconSize => 80.0;
  double get permissionButtonTopSpacing => 32.0;
  double get loadingOverlayPadding => 32.0;
  double get loadingOverlayBorderRadius => 16.0;
}
