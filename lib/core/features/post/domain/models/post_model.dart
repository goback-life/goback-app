import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/media_item_model.dart';
import 'package:cloudless/core/features/timezone/data/providers/current_timezone_provider.dart';
import 'package:cloudless/core/features/timezone/data/providers/timezone_converter_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'post_model.freezed.dart';

enum PostStatus { draft, published, failed }

@freezed
sealed class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required String id,
    required String authorId,
    required ContentType contentType,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
    required DateTime contentDate,
    required PostStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime publishedAt,
    required String publishedTimezone,
    String? parentId,
    String? description,
    @Default(false) bool isLockoutPost,
    @Default([]) List<MediaItemModel> mediaItems,
  }) = _PostModel;

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
