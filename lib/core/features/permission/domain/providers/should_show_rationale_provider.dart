import 'package:cloudless/core/features/permission/data/providers/permission_repository_provider.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/should_show_rationale_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'should_show_rationale_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> shouldShowRationale(
  Ref ref, {
  required PermissionType type,
}) async {
  final useCase = ShouldShowRationaleUseCase(
    repository: ref.watch(permissionRepositoryProvider),
    type: type,
  );
  return useCase.execute();
}
