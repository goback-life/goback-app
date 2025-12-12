import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseClientServiceContract {
  /// Initializes the Supabase client service with the provided configuration.
  ///
  /// [config] The configuration contract containing necessary setup parameters.
  ///
  /// Throws an exception if initialization fails.
  Future<void> initialize(SupabaseClientServiceConfigContract config);

  /// The Supabase client instance used to interact with Supabase services.
  SupabaseClient get client;
}
