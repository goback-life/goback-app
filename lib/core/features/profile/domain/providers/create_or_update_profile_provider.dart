import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/data/providers/profile_repository_provider.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/create_or_update_profile_use_case.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_or_update_profile_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<ProfileModel>> createOrUpdateProfile(
  Ref ref,
  String username,
  DateTime createdAt,
  DateTime updatedAt, {
  String? biography,
}) async {
  final currentUserResult = await ref.read(getCurrentUserProvider.future);

  return currentUserResult.fold(
    (user) async {
      final useCase = CreateOrUpdateProfileUseCase(
        id: user.id,
        username: username,
        biography: biography,
        repository: ref.watch(profileRepositoryProvider),
      );

      return useCase.execute();
    },
    (error) async {
      return Result.failure(error);
    },
  );
}
