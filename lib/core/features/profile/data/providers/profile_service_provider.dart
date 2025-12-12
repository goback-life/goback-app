import 'package:cloudless/core/features/profile/data/services/profile_service.dart';
import 'package:cloudless/core/features/profile/domain/contracts/profile_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_service_provider.g.dart';

@Riverpod(keepAlive: false)
ProfileServiceContract profileService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);

  return ProfileService(supabaseClient: supabaseClient, ref: ref);
}
