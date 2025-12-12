import 'package:cloudless/core/features/media_picker/data/providers/image_picker_service_provider.dart';
import 'package:cloudless/core/features/media_picker/data/repositories/image_picker_repository.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_picker_repository_provider.g.dart';

@Riverpod(keepAlive: false)
ImagePickerRepositoryContract imagePickerRepository(Ref ref) {
  final service = ref.watch(imagePickerServiceProvider);
  return ImagePickerRepository(service: service);
}
