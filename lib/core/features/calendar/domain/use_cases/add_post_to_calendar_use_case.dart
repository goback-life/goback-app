import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class AddPostToCalendarUseCase {
  const AddPostToCalendarUseCase({required this.repository});

  final CalendarRepositoryContract repository;

  Future<Result<bool>> execute({
    required String postId,
    required DateTime calendarDate,
  }) async {
    return await repository.addPostToCalendar(
      postId: postId,
      calendarDate: calendarDate,
    );
  }
}
