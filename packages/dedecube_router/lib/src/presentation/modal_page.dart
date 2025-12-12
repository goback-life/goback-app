import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;

class ModalPage<T> extends widgets.Page<T> {
  const ModalPage({
    required this.child,
    super.key,
    this.isScrollControlled = false,
    this.isDismissible = true,
    this.backgroundColor,
    this.modalBarrierColor,
  });

  final widgets.Widget child;
  final bool isScrollControlled;
  final bool isDismissible;
  final material.Color? backgroundColor;
  final material.Color? modalBarrierColor;

  @override
  widgets.Route<T> createRoute(widgets.BuildContext context) =>
      material.ModalBottomSheetRoute<T>(
        settings: this,
        builder: (context) => material.Material(
          color: backgroundColor,
          shape: const material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.only(
              topLeft: material.Radius.circular(28),
              topRight: material.Radius.circular(28),
            ),
          ),
          clipBehavior: material.Clip.antiAlias,
          child: child,
        ),
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        modalBarrierColor: modalBarrierColor,
      );
}
