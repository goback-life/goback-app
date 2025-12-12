import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_config_contract.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_client_service_contract.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientService implements SupabaseClientServiceContract {
  bool _isInitialized = false;

  @override
  Future<void> initialize(SupabaseClientServiceConfigContract config) async {
    await Supabase.initialize(
      url: config.projectUrl,
      anonKey: config.anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
    _isInitialized = true;
  }

  @override
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase has not been initialized. Call initialize() first during app startup.',
      );
    }
    return Supabase.instance.client;
  }
}
