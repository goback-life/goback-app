import 'package:dedecube_startup/dedecube_startup.dart';

class ObjectiveCompletedStorable extends Storable<bool> {
  @override
  String get key => 'objective_completed';

  @override
  StorageType get storageType => StorageType.simple;
}
