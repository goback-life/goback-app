import 'package:flutter/material.dart';

/// called easings instead of Easing to differentiate from the Material Library's one,
/// which doesn't expose the [emphasized] curve
class Easings {
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  static const Curve standard = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve standardDecelerate = Cubic(0, 0, 0, 1);
  static const Curve standardAccelerate = Cubic(0.3, 0, 1, 1);
}
