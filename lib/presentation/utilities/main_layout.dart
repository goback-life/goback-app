import 'package:flutter/material.dart';

mixin MainLayout {
  double get height => 0;
  double get width => 0;

  double get minHeight => 0;
  double get maxHeight => 0;

  double get minWidth => 0;
  double get maxWidth => 0;

  double get allPadding => 0;
  double get horizontalPadding => 0;
  double get verticalPadding => 0;
  double get leftPadding => 0;
  double get topPadding => 0;
  double get rightPadding => 0;
  double get bottomPadding => 0;

  double get allMargin => 0;
  double get horizontalMargin => 20;
  double get verticalMargin => 0;
  double get leftMargin => 0;
  double get topMargin => 0;
  double get rightMargin => 0;
  double get bottomMargin => 0;

  EdgeInsets get padding => EdgeInsets.only(
    left: allPadding + horizontalPadding + leftPadding,
    right: allPadding + horizontalPadding + rightPadding,
    top: allPadding + verticalPadding + topPadding,
    bottom: allPadding + verticalPadding + bottomPadding,
  );

  EdgeInsets get margin => EdgeInsets.only(
    left: allMargin + horizontalMargin + leftMargin,
    right: allMargin + horizontalMargin + rightMargin,
    top: allMargin + verticalMargin + topMargin,
    bottom: allMargin + verticalMargin + bottomMargin,
  );

  double get verticalSpacing => 0;
  double get horizontalSpacing => 0;
  double get controlsHorizontalSpacing => 12;
}
