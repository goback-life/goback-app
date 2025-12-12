import 'package:cloudless/core/features/permission/data/providers/permission_repository_provider.dart';
import 'package:cloudless/core/features/permission/domain/use_cases/open_app_settings_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_app_settings_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> openAppSettings(Ref ref) async {
  final useCase = OpenAppSettingsUseCase(
    repository: ref.watch(permissionRepositoryProvider),
  );
  return useCase.execute();
}
