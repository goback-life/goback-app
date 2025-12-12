import 'package:cloudless/core/features/permission/data/providers/permission_repository_provider.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/check_permission_status_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_permission_status_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<PermissionResultModel>> checkPermissionStatus(
  Ref ref, {
  required PermissionType type,
}) async {
  final useCase = CheckPermissionStatusUseCase(
    repository: ref.watch(permissionRepositoryProvider),
    type: type,
  );
  return useCase.execute();
}
