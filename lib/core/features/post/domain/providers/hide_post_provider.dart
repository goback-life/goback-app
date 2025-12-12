import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/use_cases/hide_post_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hide_post_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> hidePost(
  Ref ref, {
  required String postId,
  required String userId,
}) async {
  final useCase = HidePostUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withPostData(postId: postId, userId: userId);

  return await useCase.execute();
}
