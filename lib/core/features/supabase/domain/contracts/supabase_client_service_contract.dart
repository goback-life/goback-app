import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for Supabase client initialization and access.
abstract class SupabaseClientServiceContract {
  Future<void> initialize(SupabaseClientServiceConfigContract config);
  SupabaseClient get client;
}
