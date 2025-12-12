import 'package:dedecube_startup/dedecube_startup.dart';

class ProfileCompletedStorable extends Storable<bool> {
  @override
  String get key => 'profile_completed';

  @override
  StorageType get storageType => StorageType.simple;
}
