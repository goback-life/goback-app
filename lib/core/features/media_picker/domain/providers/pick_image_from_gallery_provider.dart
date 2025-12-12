import 'dart:io';

import 'package:cloudless/core/features/media_picker/data/providers/image_picker_repository_provider.dart';
import 'package:cloudless/core/features/media_picker/domain/use_cases/pick_image_from_gallery_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pick_image_from_gallery_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<File>> pickImageFromGallery(Ref ref) async {
  final useCase = PickImageFromGalleryUseCase(
    repository: ref.watch(imagePickerRepositoryProvider),
  );

  return useCase.execute();
}
