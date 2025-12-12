import 'dart:async';

import 'package:cloudless/core/features/profile/data/providers/profile_repository_provider.dart';
import 'package:cloudless/core/features/profile/domain/use_cases/get_profile_use_case.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_profile_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<ProfileModel?>> getProfile(Ref ref, String userId) async {
  ref.cacheFor(const Duration(minutes: 5));

  final useCase = GetProfileUseCase(
    userId: userId,
    repository: ref.watch(profileRepositoryProvider),
  );

  return useCase.execute();
}
