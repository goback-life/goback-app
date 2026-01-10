import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/link_preview_model.dart';
import 'package:cloudless/core/features/timezone/data/providers/current_timezone_provider.dart';
import 'package:cloudless/core/features/timezone/data/providers/timezone_converter_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'feed_post_model.freezed.dart';

/// Represents a post in the user's feed.
///
/// **Timezone Handling:**
/// The [createdAt] and [updatedAt] fields store timestamps in UTC timezone,
/// as received from the database and parsed during the data mapping process.
/// The conversion to the user's local timezone happens when these timestamps
/// are formatted for display in the UI.
///
/// The database stores all timestamps in UTC to ensure consistent chronological
/// ordering across all users regardless of their timezone.
@freezed
sealed class FeedPostModel with _$FeedPostModel {
  const FeedPostModel._();

  const factory FeedPostModel({
    required String id,
    required String authorId,
    required DateTime contentDate,
    required DateTime publishedAt,
    required String publishedTimezone,
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
    String? parentId,
    String? parentAuthorId,
    String? parentThumbnailUrl,
    String? parentAuthorUsername,
    ContentType? parentContentType,
    DateTime? parentDeletedAt,
    String? authorUsername,
    String? imageUrl,
    String? videoUrl,
    String? authorAvatarUrl,
    String? description,
    @Default(false) bool isLockoutPost,
    @Default([]) List<LinkPreviewModel> linkPreviews,
  }) = _FeedPostModel;

  DateTime localPublishedAt(WidgetRef ref) {
    final currentTimezoneAsync = ref.watch(currentTimezoneProvider);

    // Use the current timezone if available, otherwise fallback to DateTime.toLocal()
    return currentTimezoneAsync.when(
      data: (timezone) => ref
          .read(timezoneConverterProvider)
          .toLocal(publishedAt.toUtc(), timezone),
      loading: () => publishedAt.toUtc().toLocal(),
      error: (_, __) => publishedAt.toUtc().toLocal(),
    );
  }


  /// Calculates the lockout end time from the post description and publishedAt timestamp.
  /// Returns null if this is not a lockout post or if the duration cannot be parsed.
  /// 
  /// The description format is: "@username is going back for X hours/minutes"
  DateTime? getLockoutEndTime() {
    if (!isLockoutPost) {
      return null;
    }

    final desc = description ?? '';
    
    // Try to parse hours first (format: "@username is going back for X hours")
    final hoursMatch = RegExp(r'is going back for (\d+) hour').firstMatch(desc);
    if (hoursMatch != null) {
      final hours = int.tryParse(hoursMatch.group(1) ?? '');
      if (hours != null && hours > 0) {
        return publishedAt.add(Duration(hours: hours));
      }
    }

    // Try to parse minutes (format: "@username is going back for X minutes")
    final minutesMatch = RegExp(r'is going back for (\d+) minute').firstMatch(desc);
    if (minutesMatch != null) {
      final minutes = int.tryParse(minutesMatch.group(1) ?? '');
      if (minutes != null && minutes > 0) {
        return publishedAt.add(Duration(minutes: minutes));
      }
    }

    return null;
  }
}
