import 'package:cloudless/core/features/auth/domain/providers/check_phone_numbers_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Hook to check which phone numbers from a list have accounts in the system.
/// 
/// Returns a Set of normalized phone numbers that exist in auth.users.
/// Returns empty set if loading or on error.
Set<String> useCheckPhoneNumbers(
  WidgetRef ref,
  List<String> phoneNumbers,
) {
  if (phoneNumbers.isEmpty) {
    return <String>{};
  }

  final asyncResult = ref.watch(checkPhoneNumbersProvider(phoneNumbers));

  return asyncResult.when(
    data: (result) => result.fold(
      (existingPhones) => existingPhones,
      (error) {
        // On error, return empty set - don't show indicators
        return <String>{};
      },
    ),
    loading: () => <String>{},
    error: (_, __) => <String>{},
  );
}

