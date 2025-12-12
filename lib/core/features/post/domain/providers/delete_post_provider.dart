import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/use_cases/delete_post_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_post_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> deletePost(
  Ref ref, {
  required String postId,
  required String authorId,
}) async {
  final useCase = DeletePostUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withPostData(postId: postId, authorId: authorId);

  return await useCase.execute();
}
