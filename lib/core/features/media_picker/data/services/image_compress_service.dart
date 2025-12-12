import 'dart:io';
import 'dart:typed_data';

import 'package:cloudless/core/features/media_picker/domain/contracts/image_compress_service_contract.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressService implements ImageCompressServiceContract {
  const ImageCompressService();

  int _getInitialQuality() =>
      environment.getInt('IMAGE_COMPRESS_INITIAL_QUALITY', 80);
  int _getMinQuality() => environment.getInt('IMAGE_COMPRESS_MIN_QUALITY', 30);
  int _getMaxSizeBytes() =>
      environment.getInt('IMAGE_COMPRESS_MAX_SIZE_BYTES', 2 * 1024 * 1024);

  @override
  Future<File?> compressImage(
    File file, {
    int? initialQuality,
    int? minQuality,
    int? maxSizeBytes,
  }) async {
    int quality = initialQuality ?? _getInitialQuality();
    final int minQ = minQuality ?? _getMinQuality();
    final int maxSize = maxSizeBytes ?? _getMaxSizeBytes();
    final String ext = file.path.split('.').last.toLowerCase();
    if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) {
      return file;
    }
    final List<int> fileBytes = await file.readAsBytes();
    List<int> compressedBytes = fileBytes;

    while (compressedBytes.length > maxSize && quality >= minQ) {
      compressedBytes = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(fileBytes),
        quality: quality,
      );
      quality -= 5;
    }

    if (compressedBytes.length > maxSize) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }
}
