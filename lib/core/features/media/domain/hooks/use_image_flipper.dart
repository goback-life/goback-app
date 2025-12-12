import 'dart:io';
import 'dart:ui' as ui;

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Hook for flipping images horizontally or vertically
AsyncCallback useImageFlipper({
  required File? imageFile,
  required void Function(File) onImageFlipped,
  required bool horizontal,
}) {
  return () async {
    if (imageFile == null) {
      return;
    }

    try {
      // Load the image
      final imageData = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a canvas to draw the flipped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Apply the transformation
      if (horizontal) {
        // Flip horizontally
        canvas
          ..translate(image.width.toDouble(), 0)
          ..scale(-1.0, 1.0);
      } else {
        // Flip vertically
        canvas
          ..translate(0, image.height.toDouble())
          ..scale(1.0, -1.0);
      }

      // Draw the image
      canvas.drawImage(image, Offset.zero, Paint());

      // Convert to image
      final picture = recorder.endRecording();
      final flippedImage = await picture.toImage(image.width, image.height);

      // Convert to bytes
      final byteData = await flippedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final buffer = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final extension = path.extension(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(
        tempDir.path,
        '${fileName}_flipped_$timestamp$extension',
      );

      final newFile = File(newPath);
      await newFile.writeAsBytes(buffer);

      // Call the callback with the new file
      onImageFlipped(newFile);
    } catch (e) {
      logger.error('Error flipping image', exception: e);
    }
  };
}
