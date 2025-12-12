import 'package:go_router/go_router.dart';

/// Extension on [GoRouterState] that maps the extra data to a typed object.
///
/// The [getTypedExtra] method attempts to cast the [extra] property to a
/// [Map<String, dynamic>] and then applies the provided fromJson function to
/// convert it into the desired type. If [extra] is not a map or if the map is empty,
/// the method calls fromJson with an empty map and returns that result.
extension GoRouterExtraMapping on GoRouterState {
  T getTypedExtra<T>(T Function(Map<String, dynamic>) fromJson) {
    if (extra is Map<String, dynamic>) {
      final map = extra! as Map<String, dynamic>;
      if (map.isNotEmpty) {
        return fromJson(map);
      }
    }
    return fromJson({});
  }
}
