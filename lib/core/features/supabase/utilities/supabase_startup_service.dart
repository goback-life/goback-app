import 'package:cloudless/core/features/supabase/data/providers/supabase_client_service_config_provider.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Initializes Supabase with environment config during app startup.
class SupabaseStartupService {
  static Future<void> initialize(WidgetRef ref) async {
    final supabaseService = ref.read(supabaseClientServiceProvider);
    final supabaseConfig = ref.read(supabaseClientConfigProvider);
    await supabaseService.initialize(supabaseConfig);
    logger.info('Supabase initialized successfully');
  }
}
