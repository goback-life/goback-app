import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ProfileActionsLayout on MainLayout {
  // Menu
  double get menuVerticalSpacing => 8.0;
  double get menuBorderRadius => 8.0;
  double get menuBorderWidth => 0.5;
  double get menuIconSize => 20.0;
  double get menuIconSpacing => 10.0;
  double get menuItemHorizontalPadding => 32.0;
  double get menuItemVerticalPadding => 10.0;
  double get menuDividerHeight => 0.5;
  double get menuShadowBlur => 4.0;
  double get menuShadowOpacity => 0.25;
  double get menuShadowOffsetY => 4.0;

  // Report modal
  double get modalHorizontalPadding => 16.0;
  double get modalVerticalPadding => 20.0;
  double get modalHorizontalMargin => 48.0;
  double get modalTitleToDescription => 20.0;
  double get modalDescriptionToActions => 24.0;
  double get modalActionSpacing => 12.0;
  double get modalBorderRadius => 20.0;
  double get modalButtonHeight => 40.0;
}
