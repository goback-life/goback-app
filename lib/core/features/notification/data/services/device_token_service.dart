import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing device tokens for push notifications.
class DeviceTokenService {
  const DeviceTokenService({required this.supabase});

  final SupabaseClient supabase;

  /// Registers a device token for push notifications.
  FutureResult<void> registerToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await supabase.rpc(
        'register_device_token',
        params: {'p_token': token, 'p_platform': platform},
      );

      final result = response as Map<String, dynamic>;
      if (result['success'] == true) {
        return Result.success(null);
      } else {
        return Result.failure(
          Exception(result['error'] ?? 'Failed to register token'),
        );
      }
    } catch (e) {
      logger.error('Failed to register device token', exception: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Unregisters a device token (for logout).
  FutureResult<void> unregisterToken(String token) async {
    try {
      final response = await supabase.rpc(
        'unregister_device_token',
        params: {'p_token': token},
      );

      final result = response as Map<String, dynamic>;
      if (result['success'] == true) {
        return Result.success(null);
      } else {
        return Result.failure(
          Exception(result['error'] ?? 'Failed to unregister token'),
        );
      }
    } catch (e) {
      logger.error('Failed to unregister device token', exception: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
