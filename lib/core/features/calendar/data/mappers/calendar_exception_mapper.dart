import 'package:cloudless/core/features/calendar/data/exceptions/calendar_operation_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarExceptionMapper {
  static Exception fromSupabaseException(Exception exception) {
    if (exception is PostgrestException) {
      return CalendarOperationException(exception.message, exception.code);
    }
    return CalendarOperationException(exception.toString(), 'UNKNOWN_ERROR');
  }
}
