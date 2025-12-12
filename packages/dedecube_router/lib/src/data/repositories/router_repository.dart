import 'package:dedecube_router/src/data/services/router_service.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

class RouterRepository implements RouterRepositoryContract {
  const RouterRepository({required this.routerService});

  final RouterService routerService;

  @override
  Future<void> push(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    return routerService.push(
      route,
      context: context,
    );
  }

  @override
  Future<void> go(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    return routerService.go(
      route,
      context: context,
    );
  }

  @override
  Future<void> replace(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    return routerService.replace(
      route,
      context: context,
    );
  }

  @override
  Future<void> pushReplacement(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    return routerService.pushReplacement(
      route,
      context: context,
    );
  }

  @override
  Future<void> pop({
    widgets.BuildContext? context,
  }) {
    return routerService.pop(
      context: context,
    );
  }

  @override
  Future<bool> canPop({
    widgets.BuildContext? context,
  }) {
    return routerService.canPop(
      context: context,
    );
  }
}
