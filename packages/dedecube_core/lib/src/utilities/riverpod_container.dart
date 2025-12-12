import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Returns a [ProviderContainer] instance.
///
/// This function returns the [ProviderContainer] instance, which is used to manage the state and dependencies.
ProviderContainer riverpodContainer() {
  return GetIt.I.get<ProviderContainer>();
}
