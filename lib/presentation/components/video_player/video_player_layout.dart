import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin VideoPlayerLayout on MainLayout {
  // Close button
  double get closeButtonMargin => 8.0;
  double get closeButtonPadding => 10.0;

  // Play/Pause button
  double get playPauseIconSize => 48.0;

  // Controls
  double get controlsAnimationDuration => 300.0; // milliseconds
  double get controlsAutoHideDuration => 3.0; // seconds
  double get controlsOverlayAlpha => 0.3;
  double get closeButtonBackgroundAlpha => 0.5;

  // Progress bar
  double get progressBarHorizontalPadding => 16.0;
  double get progressBarVerticalPadding => 8.0;
  double get progressBarBufferedAlpha => 0.3;
  double get progressBarBackgroundAlpha => 0.2;

  double get framePickerFrameWidth => 40;
  double get framePickerHeight => 100;
  double get frameProgressBarIndicatorVerticalMargin => 4;
  double get frameProgressBarVerticalMargin => 10;
  double get frameProgressBarHorizontalMargin => 12;
  double get framePickerPlayButtonRadius => 8;
  double get framePickerConfirmButtonTopMargin => 8;
}
