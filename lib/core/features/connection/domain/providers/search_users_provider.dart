import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_users_provider.g.dart';

typedef SearchUserResult = (ProfileModel, ConnectionStatus);

@Riverpod(keepAlive: false)
Future<Result<List<SearchUserResult>>> searchUsers(
  Ref ref,
  String query,
) async {
  final service = ref.watch(connectionServiceProvider);
  final result = await service.searchUsers(query);

  return result.fold(
    (rows) {
      final results = rows.map((row) {
        final profile = ProfileModel(
          id: row['user_id'] as String,
          username: row['username'] as String,
          avatarUrl: row['avatar_url'] as String?,
        );
        final status = ConnectionStatus.fromString(
          row['connection_status'] as String? ?? 'none',
        );
        return (profile, status);
      }).toList();
      return Result.success(results);
    },
    (error) => Result.failure(error),
  );
}
