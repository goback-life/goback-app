import 'package:cloudless/core/features/supabase/data/services/supabase_client_service.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_client_service_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClientServiceContract supabaseClientService(Ref ref) {
  return SupabaseClientService();
}
