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
    required DateTime publishedAt,
    required String publishedTimezone,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<String> taggedUsernames,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required int thumbnailWidth,
    required int thumbnailHeight,
    required ContentType contentType,
    required bool isAuthorConnected,
    String? authorUsername,
    String? imageUrl,
    String? videoUrl,
    String? authorAvatarUrl,
    String? description,
    /// Reference to lockout_sessions table if this is a lockout post
    String? lockoutId,
    /// When this post was saved to calendar (null if not saved)
    DateTime? calendarSavedAt,
    @Default([]) List<LinkPreviewModel> linkPreviews,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
  }) = _FeedPostModel;

  /// Returns true if this is a lockout post (has a lockout session reference)
  bool get isLockoutPost => lockoutId != null;

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
}
