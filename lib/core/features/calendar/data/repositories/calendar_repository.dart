import 'package:cloudless/core/features/calendar/data/mappers/calendar_exception_mapper.dart';
import 'package:cloudless/core/features/calendar/data/mappers/calendar_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_service_contract.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class CalendarRepository implements CalendarRepositoryContract {
  const CalendarRepository({
    required this.calendarService,
    required this.calendarPostMapper,
  });

  final CalendarServiceContract calendarService;
  final CalendarPostDtoToModelMapper calendarPostMapper;

  @override
  FutureResult<List<CalendarPostModel>> getCalendarPosts({
    required String userId,
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    int limit = 42,
  }) async {
    try {
      // Convert referenceDate to year/month for the service
      final dtos = await calendarService.getCalendarPosts(
        userId: userId,
        year: referenceDate.year,
        month: referenceDate.month,
      );

      final models = calendarPostMapper.mapDtoList(dtos);
      return Result.success(models);
    } catch (e) {
      return Result.failure(
        CalendarExceptionMapper.fromSupabaseException(
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
