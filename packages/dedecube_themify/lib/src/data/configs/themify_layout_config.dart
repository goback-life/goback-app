/// A configuration class defining layout parameters for UI components.
///
/// This class encapsulates various layout-related properties that control the spacing and
/// dimensions of UI widgets. All properties are optional and default to 0 if not provided.
class ThemifyLayoutConfig {
  const ThemifyLayoutConfig({
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.leftPadding = 0,
    this.rightPadding = 0,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.height = 0,
    this.width = 0,
    this.borderRadius = 0,
    this.borderWidth = 0,
    this.space = 0,
    this.iconSize = 0,
  });

  /// The horizontal padding for the widget.
  final double horizontalPadding;

  /// The vertical padding for the widget.
  final double verticalPadding;

  /// The left padding for the widget.
  final double leftPadding;

  /// The right padding for the widget.
  final double rightPadding;

  /// The top padding for the widget.
  final double topPadding;

  /// The bottom padding for the widget.
  final double bottomPadding;

  /// The height of the widget.
  final double height;

  /// The width of the widget.
  final double width;

  /// The border radius of the widget.
  final double borderRadius;

  /// The border width of the widget.
  final double borderWidth;

  /// A parameter for spacing.
  final double space;

  /// The size of the icon.
  final double iconSize;
}
