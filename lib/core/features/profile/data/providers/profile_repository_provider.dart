import 'package:cloudless/core/features/profile/data/providers/profile_service_provider.dart';
import 'package:cloudless/core/features/profile/data/repositories/profile_repository.dart';
import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository_provider.g.dart';

@Riverpod(keepAlive: false)
ProfileRepositoryContract profileRepository(Ref ref) {
  return ProfileRepository(profileService: ref.watch(profileServiceProvider));
}
