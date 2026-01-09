import 'package:cloudless/core/features/auth/data/providers/phone_check_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_phone_numbers_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<Set<String>>> checkPhoneNumbers(
  Ref ref,
  List<String> phoneNumbers,
) async {
  final service = ref.watch(phoneCheckServiceProvider);
  return service.checkPhoneNumbersExist(phoneNumbers);
}



