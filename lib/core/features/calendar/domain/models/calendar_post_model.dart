import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'calendar_post_model.freezed.dart';

@freezed
sealed class CalendarPostModel with _$CalendarPostModel {
  const factory CalendarPostModel({
    required String postId,
    required String authorId,
    required String authorUsername,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<String> taggedUsernames,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required int thumbnailWidth,
    required int thumbnailHeight,
    required ContentType contentType,
    required bool isAuthorConnected,
    required bool isOwnPost,
    required DateTime publishedAt,
    required String publishedTimezone,
    String? authorAvatarUrl,
    String? thumbnailUrl,
    String? description,
    String? videoUrl,
    /// The lockout session ID this post was created from
    String? lockoutId,
    /// When this post was saved to calendar (legacy, now optional)
    DateTime? calendarSavedAt,
  }) = _CalendarPostModel;
}
