import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:cloudless/core/features/connection/data/repositories/connection_repository.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_repository_provider.g.dart';

@Riverpod(keepAlive: false)
ConnectionRepositoryContract connectionRepository(Ref ref) {
  return ConnectionRepository(
    connectionService: ref.watch(connectionServiceProvider),
  );
}
