import 'dart:io';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/data/providers/profile_repository_provider.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/upload_avatar_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_avatar_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<String>> uploadAvatar(Ref ref, File imageFile) async {
  final currentUserResult = await ref.read(getCurrentUserProvider.future);

  return currentUserResult.fold(
    (user) async {
      final useCase = UploadAvatarUseCase(
        userId: user.id,
        imageFile: imageFile,
        repository: ref.watch(profileRepositoryProvider),
      );

      return useCase.execute();
    },
    (error) async {
      return Result.failure(error);
    },
  );
}
