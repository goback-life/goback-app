import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/get_contact_with_permission_use_case.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_contact_with_permission_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<ContactModel>>> getContactWithPermission(Ref ref) async {
  final repository = ref.read(connectionRepositoryProvider);
  final useCase = GetContactWithPermissionUseCase(repository: repository);
  return await useCase.execute();
}
