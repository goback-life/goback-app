import 'package:cloudless/core/features/nfc/data/services/nfc_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfc_service_provider.g.dart';

@Riverpod(keepAlive: true)
NfcService nfcService(NfcServiceRef ref) => NfcService();
