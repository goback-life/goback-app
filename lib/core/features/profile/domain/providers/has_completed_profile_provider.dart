import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/data/providers/profile_repository_provider.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/has_completed_profile_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_completed_profile_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> hasCompletedProfile(Ref ref) async {
  final currentUserResult = await ref.read(getCurrentUserProvider.future);

  return currentUserResult.fold(
    (user) async {
      final useCase = HasCompletedProfileUseCase(
        userId: user.id,
        repository: ref.watch(profileRepositoryProvider),
      );

      return useCase.execute();
    },
    (error) async {
      return Result.failure(error);
    },
  );
}
