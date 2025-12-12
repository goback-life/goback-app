import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class RemovePostFromCalendarUseCase {
  const RemovePostFromCalendarUseCase({required this.repository});

  final CalendarRepositoryContract repository;

  Future<Result<bool>> execute({required DateTime calendarDate}) async {
    return await repository.removePostFromCalendar(calendarDate: calendarDate);
  }
}
