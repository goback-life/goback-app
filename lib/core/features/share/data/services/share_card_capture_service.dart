import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a widget as a PNG image and opens the OS share sheet.
class ShareCardCaptureService {
  /// Renders [card] offscreen, captures it as a 1080x1350 PNG, and shares it.
  Future<void> captureAndShare(BuildContext context, Widget card) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        child: RepaintBoundary(
          key: key,
          child: MediaQuery(
            data: MediaQuery.of(context),
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: SizedBox(width: 360, height: 450, child: card),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/goback_share_$ts.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // iOS requires sharePositionOrigin for the share sheet popover anchor.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromCenter(
              center: MediaQuery.of(context).size.center(Offset.zero),
              width: 100,
              height: 100,
            );

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin),
      );
    } finally {
      entry.remove();
    }
  }
}
