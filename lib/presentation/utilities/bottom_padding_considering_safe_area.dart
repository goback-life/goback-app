import 'package:flutter/widgets.dart';

extension BottomPaddingConsideringSafeArea on num {
  double bottomPaddingConsideringSafeArea(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return bottomSafeArea >= this ? 0 : this - bottomSafeArea;
  }
}
