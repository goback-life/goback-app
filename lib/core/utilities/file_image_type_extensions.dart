import 'dart:io';
import 'dart:typed_data';

/// Extension methods for detecting MIME content types of image files.
extension FileImageTypeExtensions on File {
  /// Detects the MIME content type by inspecting the file header magic numbers.
  ///
  /// Supported types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`.
  /// Returns `image/jpeg` as fallback for unknown types or errors.
  Future<String> detectImageContentType() async {
    RandomAccessFile? raf;
    const fallback = 'image/jpeg';
    try {
      raf = await open();
      final headerBytes = await raf.read(12);

      // Ensure we have a Uint8List for the helper methods.
      final header = headerBytes;

      return _identifyImageType(header);
    } catch (_) {
      return fallback;
    } finally {
      try {
        await raf?.close();
      } catch (_) {
        // ignore close errors
      }
    }
  }

  /// Identifies image type from header bytes using magic number signatures.
  String _identifyImageType(Uint8List header) {
    // JPEG: FF D8 FF
    if (_matchesSignature(header, [0xFF, 0xD8, 0xFF])) {
      return 'image/jpeg';
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (_matchesSignature(header, [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ])) {
      return 'image/png';
    }

    // GIF: 47 49 46
    if (_matchesSignature(header, [0x47, 0x49, 0x46])) {
      return 'image/gif';
    }

    // WEBP: RIFF....WEBP (check positions 0-3 and 8-11)
    if (header.length >= 12 &&
        _matchesSignature(header, [0x52, 0x49, 0x46, 0x46], offset: 0) &&
        _matchesSignature(header, [0x57, 0x45, 0x42, 0x50], offset: 8)) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  /// Checks if header matches expected byte signature at given offset.
  bool _matchesSignature(
    Uint8List header,
    List<int> signature, {
    int offset = 0,
  }) {
    if (header.length < offset + signature.length) {
      return false;
    }

    for (int i = 0; i < signature.length; i++) {
      if (header[offset + i] != signature[i]) {
        return false;
      }
    }
    return true;
  }
}
