import 'package:cloudless/core/features/media_picker/data/services/image_compress_service.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_compress_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_compress_service_provider.g.dart';

@Riverpod(keepAlive: false)
ImageCompressServiceContract imageCompressService(Ref ref) {
  return const ImageCompressService();
}
