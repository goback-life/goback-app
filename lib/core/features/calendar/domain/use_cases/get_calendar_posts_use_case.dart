import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetCalendarPostsUseCase {
  const GetCalendarPostsUseCase({required this.repository});

  final CalendarRepositoryContract repository;

  Future<Result<List<CalendarPostModel>>> execute({
    required String userId,
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    int limit = 42,
  }) async {
    return await repository.getCalendarPosts(
      userId: userId,
      referenceDate: referenceDate,
      direction: direction,
      limit: limit,
    );
  }
}
