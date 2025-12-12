import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';

/// Extension on [BaseRoutable] that automatically derives a route name from its runtime type.
///
/// The [name] property converts the runtime type (classified in CamelCase) into a snake_case
/// string. For example, if an instance's runtime type is `Home`, [name] will return
/// `home`.
extension RouterRouteNameExtension on BaseRoutable {
  String get name => runtimeType.toString().snakeCase();
}
