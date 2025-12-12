import 'package:cloudless/core/features/supabase/data/providers/supabase_client_service_config_provider.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Utility service for initializing Supabase during app startup.
class SupabaseStartupService {
  /// Initializes Supabase with configuration from environment variables.
  ///
  /// This method should be called during app startup to ensure Supabase
  /// is properly configured before any client access.
  ///
  /// Throws:
  /// - [Exception] if environment variables are missing
  /// - [Exception] if Supabase initialization fails
  static Future<void> initialize(WidgetRef ref) async {
    final supabaseService = ref.read(supabaseClientServiceProvider);
    final supabaseConfig = ref.read(supabaseClientConfigProvider);

    await supabaseService.initialize(supabaseConfig);
    logger.info('Supabase initialized successfully');
  }
}
