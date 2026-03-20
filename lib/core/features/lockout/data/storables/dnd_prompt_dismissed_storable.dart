import 'package:dedecube_startup/dedecube_startup.dart';

class DndPromptDismissedStorable extends Storable<bool> {
  @override
  String get key => 'dnd_prompt_dismissed';

  @override
  StorageType get storageType => StorageType.simple;
}
