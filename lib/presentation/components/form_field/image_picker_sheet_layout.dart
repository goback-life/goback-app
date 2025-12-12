import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin ImagePickerSheetLayout on MainLayout {
  double get sheetBorderRadius => 20;

  @override
  double get width => 40;

  @override
  double get height => 4;

  double get sheetHandleRadius => 2;

  @override
  double get verticalSpacing => 24;

  double get sheetActionButtonBottomSpacing => 12;
  double get sheetCancelButtonTopSpacing => 0;

  double get imageMaxWidth => 1024;
  double get imageMaxHeight => 1024;
  int get imageQuality => 85;
}
