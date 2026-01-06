import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneCheckService {
  const PhoneCheckService({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  /// Checks which phone numbers exist in auth.users
  /// Returns a Set of normalized phone numbers that exist in the database
  FutureResult<Set<String>> checkPhoneNumbersExist(
    List<String> phoneNumbers,
  ) async {
    try {
      if (phoneNumbers.isEmpty) {
        return Result.success(<String>{});
      }

      // Normalize all phone numbers before sending to RPC
      final normalizedPhones = PhoneNumberNormalizer.normalizeList(phoneNumbers);

      if (normalizedPhones.isEmpty) {
        return Result.success(<String>{});
      }

      // Call RPC function
      final response = await _supabaseClient.rpc(
        'check_phone_numbers_exist',
        params: {'phone_numbers': normalizedPhones},
      );

      // Response is a List<String> of phone numbers that exist
      // Normalize the response to ensure consistent format (remove any + signs)
      final existingPhones = (response as List<dynamic>?)
              ?.map((phone) => PhoneNumberNormalizer.normalize(phone.toString()))
              .where((phone) => phone.isNotEmpty)
              .toSet() ??
          <String>{};

      return Result.success(existingPhones);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}

