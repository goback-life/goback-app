import 'package:cloudless/core/features/media_picker/data/services/image_picker_service.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_picker_service_provider.g.dart';

@Riverpod(keepAlive: false)
ImagePickerServiceContract imagePickerService(Ref ref) {
  return ImagePickerService();
}
