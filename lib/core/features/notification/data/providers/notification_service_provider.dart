import 'package:cloudless/core/features/notification/data/services/notification_service.dart';
import 'package:cloudless/core/features/notification/data/services/notification_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service_provider.g.dart';

@Riverpod(keepAlive: false)
NotificationServiceContract notificationService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return NotificationService(supabaseClient: supabaseClient);
}

