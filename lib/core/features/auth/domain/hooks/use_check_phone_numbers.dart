import 'package:cloudless/core/features/auth/domain/providers/check_phone_numbers_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Returns normalized phone numbers that have accounts. Empty set on error.
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
