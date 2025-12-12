import 'package:cloudless/core/features/calendar/data/providers/calendar_repository_provider.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:cloudless/core/features/calendar/domain/use_cases/get_calendar_posts_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_calendar_posts_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<CalendarPostModel>>> getCalendarPosts(
  Ref ref, {
  required String userId,
  required DateTime referenceDate,
  required CalendarLoadDirection direction,
  int limit = 42,
}) async {
  final useCase = GetCalendarPostsUseCase(
    repository: ref.watch(calendarRepositoryProvider),
  );

  return await useCase.execute(
    userId: userId,
    referenceDate: referenceDate,
    direction: direction,
    limit: limit,
  );
}
