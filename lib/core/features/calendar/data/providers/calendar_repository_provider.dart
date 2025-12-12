import 'package:cloudless/core/features/calendar/data/mappers/calendar_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/calendar/data/providers/calendar_service_provider.dart';
import 'package:cloudless/core/features/calendar/data/repositories/calendar_repository.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CalendarRepositoryContract calendarRepository(Ref ref) {
  return CalendarRepository(
    calendarService: ref.watch(calendarServiceProvider),
    calendarPostMapper: CalendarPostDtoToModelMapper(),
  );
}
