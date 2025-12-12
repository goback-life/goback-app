import 'dart:io';

import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class PickImageFromCameraUseCase
    implements UseCaseContract<FutureResult<File>> {
  const PickImageFromCameraUseCase({required this.repository});

  final ImagePickerRepositoryContract repository;

  @override
  FutureResult<File> execute() async {
    return await repository.pickFromCamera();
  }
}
