import 'package:cloudless/core/features/calendar/data/providers/calendar_repository_provider.dart';
import 'package:cloudless/core/features/calendar/domain/use_cases/add_post_to_calendar_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_post_to_calendar_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> addPostToCalendar(
  Ref ref, {
  required String postId,
}) async {
  final useCase = AddPostToCalendarUseCase(
    repository: ref.watch(calendarRepositoryProvider),
  );

  return await useCase.execute(postId: postId);
}
