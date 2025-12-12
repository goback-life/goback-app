import 'package:flutter/material.dart';

extension KeyboardDismiss on Widget {
  Widget dismissKeyboardOnTap() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: this,
    );
  }
}
