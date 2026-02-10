import 'package:cloudless/core/features/notification/data/services/device_token_service.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_token_service_provider.g.dart';

@riverpod
DeviceTokenService deviceTokenService(Ref ref) {
  return DeviceTokenService(supabase: ref.watch(supabaseClientProvider));
}
