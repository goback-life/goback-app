import 'package:cloudless/core/features/auth/data/services/phone_check_service.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_check_service_provider.g.dart';

@Riverpod(keepAlive: false)
PhoneCheckService phoneCheckService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return PhoneCheckService(supabaseClient: supabaseClient);
}

