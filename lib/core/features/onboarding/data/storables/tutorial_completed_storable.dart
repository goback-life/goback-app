import 'package:dedecube_startup/dedecube_startup.dart';

class TutorialCompletedStorable extends Storable<bool> {
  @override
  String get key => 'tutorial_v1_completed';

  @override
  StorageType get storageType => StorageType.simple;
}
