import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:cloudless/core/features/post/domain/models/post_report_model.dart';
import 'package:cloudless/core/features/post/domain/use_cases/report_post_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_post_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<PostReportModel>> reportPost(
  Ref ref, {
  required String postId,
  required String userId,
  required PostReportReason reason,
}) async {
  final useCase = ReportPostUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withReportData(postId: postId, userId: userId, reason: reason.value);

  return await useCase.execute();
}
