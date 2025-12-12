import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'calendar_post_model.freezed.dart';

@freezed
sealed class CalendarPostModel with _$CalendarPostModel {
  const factory CalendarPostModel({
    required String calendarId,
    required DateTime calendarDate,
    required String postId,
    required String authorId,
    required String authorUsername,
    required DateTime contentDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<String> taggedUsernames,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required List<String> parentExcludedUserIds,
    required int thumbnailWidth,
    required int thumbnailHeight,
    required ContentType contentType,
    required bool isAuthorConnected,
    required bool isOwnPost,
    required bool isToday,
    required DateTime publishedAt,
    required String publishedTimezone,
    String? authorAvatarUrl,
    String? thumbnailUrl,
    String? description,
    String? videoUrl,
    String? parentId,
    String? parentAuthorId,
    String? parentThumbnailUrl,
    String? parentAuthorUsername,
    ContentType? parentContentType,
    DateTime? parentDeletedAt,
  }) = _CalendarPostModel;
}
