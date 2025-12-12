import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';

class SupabaseClientServiceConfig
    implements SupabaseClientServiceConfigContract {
  SupabaseClientServiceConfig({
    required this.projectUrl,
    required this.anonKey,
  });

  @override
  final String projectUrl;

  @override
  final String anonKey;
}
