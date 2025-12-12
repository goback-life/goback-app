import 'package:dedecube_core/dedecube_core.dart';

part 'post_reaction_model.freezed.dart';

@freezed
sealed class PostReactionModel with _$PostReactionModel {
  const factory PostReactionModel({
    required String id,
    required String postId,
    required String userId,
    required String reaction,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PostReactionModel;
}
