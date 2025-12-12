import 'package:cloudless/core/features/calendar/data/services/calendar_service.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_service_provider.g.dart';

@Riverpod(keepAlive: true)
CalendarServiceContract calendarService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);

  return CalendarService(supabaseClient: supabaseClient, ref: ref);
}
