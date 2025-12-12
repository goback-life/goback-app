import 'package:cloudless/core/features/profile/data/providers/profile_repository_provider.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/check_username_availability_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_username_availability_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> checkUsernameAvailability(Ref ref, String username) async {
  final useCase = CheckUsernameAvailabilityUseCase(
    username: username,
    repository: ref.watch(profileRepositoryProvider),
  );

  return useCase.execute();
}
