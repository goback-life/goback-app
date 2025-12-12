import 'package:cloudless/core/features/permission/data/providers/permission_repository_provider.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/request_permission_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'request_permission_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<PermissionResultModel>> requestPermission(
  Ref ref, {
  required PermissionType type,
}) async {
  final useCase = RequestPermissionUseCase(
    repository: ref.watch(permissionRepositoryProvider),
    type: type,
  );
  return useCase.execute();
}
