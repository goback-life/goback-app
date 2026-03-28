part of 'package:cloudless/presentation/components/full_screen_image.dart';

/// CustomPainter to draw a ui.Image directly
class _UiImagePainter extends CustomPainter {
  _UiImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the scale to fit the image in the available space
    final double imageAspectRatio = image.width / image.height;
    final double canvasAspectRatio = size.width / size.height;

    double drawWidth;
    double drawHeight;

    if (imageAspectRatio > canvasAspectRatio) {
      // Image is wider than canvas
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
    } else {
      // Image is taller than canvas
      drawHeight = size.height;
      drawWidth = size.height * imageAspectRatio;
    }

    // Center the image
    final double offsetX = (size.width - drawWidth) / 2;
    final double offsetY = (size.height - drawHeight) / 2;

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect dstRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(_UiImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
