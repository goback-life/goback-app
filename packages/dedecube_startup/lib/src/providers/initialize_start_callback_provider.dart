import 'package:dedecube_core/dedecube_core.dart';

typedef InitializeStartCallback = void Function(WidgetRef ref);

final initializeStartCallbackProvider = StateProvider<InitializeStartCallback?>(
  (ref) => null,
);
