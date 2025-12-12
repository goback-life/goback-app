import 'package:cloudless/core/features/auth/data/services/auth_service.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service_provider.g.dart';

@Riverpod(keepAlive: false)
AuthServiceContract authService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AuthService(supabaseClient: supabaseClient);
}
