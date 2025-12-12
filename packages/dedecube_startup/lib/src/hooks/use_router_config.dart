import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/dedecube_router.dart';

CustomRouter useRouterConfig() {
  return useMemoized<CustomRouter>(() => router.initialize, []);
}
