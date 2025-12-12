import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'parent_post_reference_model.freezed.dart';

/// Model that contains only the essential information about a parent post
/// needed to show context when creating a reply.
@freezed
sealed class ParentPostReferenceModel with _$ParentPostReferenceModel {
  const factory ParentPostReferenceModel({
    required String id,
    required String authorUsername,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
    required ContentType contentType,
    String? authorId,
    @Default(false) bool isDeleted,
  }) = _ParentPostReferenceModel;
}
