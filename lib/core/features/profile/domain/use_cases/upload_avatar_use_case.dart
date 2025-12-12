import 'dart:io';

import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class UploadAvatarUseCase implements UseCaseContract<FutureResult<String>> {
  const UploadAvatarUseCase({
    required this.userId,
    required this.imageFile,
    required this.repository,
  });

  final String userId;
  final File imageFile;
  final ProfileRepositoryContract repository;

  @override
  FutureResult<String> execute() async {
    return repository.uploadAvatar(userId, imageFile);
  }
}
