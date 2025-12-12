import 'package:dedecube_core/dedecube_core.dart';

typedef InitializeCompleteCallback = void Function(
    WidgetRef ref, bool isSuccess);

final initializeCompleteCallbackProvider =
    StateProvider<InitializeCompleteCallback?>((ref) => null);
