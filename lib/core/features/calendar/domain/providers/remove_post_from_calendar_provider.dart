import 'package:cloudless/core/features/calendar/data/providers/calendar_repository_provider.dart';
import 'package:cloudless/core/features/calendar/domain/use_cases/remove_post_from_calendar_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remove_post_from_calendar_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> removePostFromCalendar(
  Ref ref, {
  required String postId,
}) async {
  final useCase = RemovePostFromCalendarUseCase(
    repository: ref.watch(calendarRepositoryProvider),
  );

  return await useCase.execute(postId: postId);
}
