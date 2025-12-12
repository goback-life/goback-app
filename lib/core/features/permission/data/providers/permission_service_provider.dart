import 'package:cloudless/core/features/permission/data/services/permission_service.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service_provider.g.dart';

@Riverpod(keepAlive: false)
PermissionServiceContract permissionService(Ref ref) {
  return PermissionService();
}
