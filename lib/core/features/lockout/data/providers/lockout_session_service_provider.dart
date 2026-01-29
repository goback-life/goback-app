import 'package:cloudless/core/features/lockout/data/services/lockout_session_service.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lockout_session_service_provider.g.dart';

@riverpod
LockoutSessionService lockoutSessionService(Ref ref) {
  return LockoutSessionService(supabase: ref.watch(supabaseClientProvider));
}
