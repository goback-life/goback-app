import 'package:cloudless/core/features/crashlytics/data/services/crashlytics_service.dart';
import 'package:cloudless/core/features/crashlytics/domain/contracts/crashlytics_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crashlytics_service_provider.g.dart';

@Riverpod(keepAlive: true)
CrashlyticsServiceContract crashlyticsService(Ref ref) {
  return CrashlyticsService();
}
