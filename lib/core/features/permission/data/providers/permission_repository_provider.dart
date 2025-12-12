import 'package:cloudless/core/features/permission/data/providers/permission_service_provider.dart';
import 'package:cloudless/core/features/permission/data/repositories/permission_repository.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_repository_provider.g.dart';

@Riverpod(keepAlive: false)
PermissionRepositoryContract permissionRepository(Ref ref) {
  return PermissionRepository(service: ref.watch(permissionServiceProvider));
}
