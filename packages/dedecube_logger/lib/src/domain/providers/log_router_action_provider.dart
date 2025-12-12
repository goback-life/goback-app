import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_repository_provider.dart';
import 'package:dedecube_logger/src/domain/use_cases/log_router_action_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_router_action_provider.g.dart';

@Riverpod(keepAlive: false)
void logRouterAction(
  Ref ref,
  String routeAction,
  String? routeName,
  Map<String, dynamic>? routeExtraData,
) {
  final logUseCase = LogRouterActionUseCase(
    repository: ref.watch(loggerRepositoryProvider),
    action: routeAction,
    name: routeName,
    extraData: routeExtraData,
  );

  return logUseCase.execute();
}
