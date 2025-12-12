import 'dart:developer';

import 'package:dedecube_router/src/data/observers/router_observer.dart';
import 'package:dedecube_router/src/domain/contracts/router_contract.dart';

/// Extension on [RouterContract] about stack.
///
extension RouterStackExtension on RouterContract {
  /// Retrieves and logs the current stack trace maintained by the [RouterObserver].
  /// This helps with debugging navigation issues by providing a snapshot of the current route stack.
  void logStack() {
    log(RouterObserver.stack.toString());
  }

  /// This getter retrieves the list of route names stored in the `RouterObserver.stack`.
  /// It can be used to inspect or manipulate the navigation stack of the application.
  List<String> get stack => RouterObserver.stack;
}
