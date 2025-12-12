import 'package:cloudless/core/features/connection/data/services/connection_service.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_service_provider.g.dart';

@Riverpod(keepAlive: false)
ConnectionServiceContract connectionService(Ref ref) {
  return ConnectionService(
    supabase: ref.watch(supabaseClientProvider),
    ref: ref,
  );
}
