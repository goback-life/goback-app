import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/exceptions/router_duplicate_paths_exception.dart';

class RouterUtilities {
  /// Checks the uniqueness of route paths defined in the [RouterConfig].
  ///
  /// This method performs the following actions:
  ///   1. Iterates through each [BaseRoutable] in the [RouterConfig]'s routes.
  ///   2. Maintains a set of seen route properties (for example, 'path' and 'name').
  ///   3. If a duplicate property is encountered (e.g. a duplicate 'path' or 'name'),
  ///      it throws a [RouterDuplicateException] containing the duplicate property's name and its value.
  ///   4. If all properties are unique, the validation completes successfully.
  static void validateRoutes(
    RouterConfig config,
  ) async {
    final seenPaths = <String>{};
    final seenNames = <String>{};

    for (final route in config.routes) {
      if (!seenPaths.add(route.path)) {
        throw RouterDuplicateException(
          property: 'path',
          value: route.path,
        );
      }

      if (!seenNames.add(route.name)) {
        throw RouterDuplicateException(
          property: 'name',
          value: route.name,
        );
      }
    }
  }
}
