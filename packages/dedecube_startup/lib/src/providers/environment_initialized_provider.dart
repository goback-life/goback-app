import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'environment_initialized_provider.g.dart';

@Riverpod(keepAlive: true)
class EnvironmentInitializedNotifier extends _$EnvironmentInitializedNotifier {
  @override
  bool build() {
    return true;
  }

  set isInitialized(bool value) {
    state = value;
  }
}
