import 'package:cloudless/core/features/connection/data/providers/connection_service_provider.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_outgoing_requests_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<ConnectionRequestModel>>> getOutgoingRequests(
  Ref ref,
) async {
  final service = ref.watch(connectionServiceProvider);
  final result = await service.getOutgoingRequests();

  return result.fold(
    (dtos) {
      final models = dtos.map((dto) {
        return ConnectionRequestModel(
          requestId: dto.requestId,
          profile: ProfileModel(
            id: dto.receiverId,
            username: dto.receiverUsername,
            avatarUrl: dto.receiverAvatarUrl,
          ),
          createdAt: DateTime.parse(dto.createdAt),
          expiresAt: DateTime.parse(dto.expiresAt),
        );
      }).toList();
      return Result.success(models);
    },
    (error) => Result.failure(error),
  );
}
