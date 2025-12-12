import 'package:flutter/material.dart';

/// A utility widget that creates empty space with specified dimensions.
///
/// This widget is used to add spacing between other widgets, either vertically
/// or horizontally. It's essentially a wrapper around [SizedBox] with convenient
/// named constructors for common use cases.
class CustomSpace extends StatelessWidget {
  /// Creates a vertical space with the specified [height].
  ///
  /// If [wide] is true, the space will extend to the full available width.
  const CustomSpace.vertical(this.height, {super.key, bool wide = false})
      : width = wide ? double.infinity : 0;

  /// Creates a horizontal space with the specified [width].
  ///
  /// If [tall] is true, the space will extend to the full available height.
  const CustomSpace.horizontal(this.width, {super.key, bool tall = false})
      : height = tall ? double.infinity : 0;

  /// The width of the space.
  final double width;

  /// The height of the space.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
    );
  }
}
