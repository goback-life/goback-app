import 'package:dedecube_startup/dedecube_startup.dart';

class OnboardingCompletedStorable extends Storable<bool> {
  @override
  String get key => 'onboarding_v2_completed';

  @override
  StorageType get storageType => StorageType.simple;
}
