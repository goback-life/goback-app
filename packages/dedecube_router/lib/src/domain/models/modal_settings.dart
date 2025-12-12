import 'package:flutter/material.dart' as material;

class ModalSettings {
  /// Creates modal settings with default values.
  const ModalSettings({
    this.isScrollControlled = false,
    this.isDismissible = true,
    this.backgroundColor,
    this.modalBarrierColor,
  });

  /// Whether the modal should be scrollable.
  final bool isScrollControlled;

  /// Whether the modal can be dismissed by tapping outside.
  final bool isDismissible;

  /// Optional background color for the modal.
  final material.Color? backgroundColor;

  /// Optional modal barrier color.
  final material.Color? modalBarrierColor;
}
