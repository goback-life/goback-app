import 'package:dedecube_startup/dedecube_startup.dart';

class TutorialPhaseStorable extends Storable<String> {
  @override
  String get key => 'tutorial_v1_phase';

  @override
  StorageType get storageType => StorageType.simple;
}
