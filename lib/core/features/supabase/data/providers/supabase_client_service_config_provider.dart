import 'package:cloudless/core/features/supabase/data/configs/supabase_client_service_config.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_client_service_config_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClientServiceConfigContract supabaseClientConfig(Ref ref) {
  final String? projectUrl = environment.tryGetString('SUPABASE_PROJECT_URL');
  if (projectUrl == null || projectUrl.isEmpty) {
    throw Exception('SUPABASE_PROJECT_URL not configured.');
  }
  final String? anonKey = environment.tryGetString('SUPABASE_ANON_KEY');
  if (anonKey == null || anonKey.isEmpty) {
    throw Exception('SUPABASE_ANON_KEY not configured.');
  }

  return SupabaseClientServiceConfig(projectUrl: projectUrl, anonKey: anonKey);
}
