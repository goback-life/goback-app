import 'package:cloudless/core/features/profile/data/services/user_report_service.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_report_service_provider.g.dart';

@Riverpod(keepAlive: false)
UserReportService userReportService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);

  return UserReportService(supabaseClient: supabaseClient);
}
