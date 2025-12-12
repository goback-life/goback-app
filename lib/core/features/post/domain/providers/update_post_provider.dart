import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/use_cases/update_post_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_post_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<PostModel>> updatePost(Ref ref, PostDataModel postData) async {
  final useCase = UpdatePostUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withPostData(postData);

  return await useCase.execute();
}
